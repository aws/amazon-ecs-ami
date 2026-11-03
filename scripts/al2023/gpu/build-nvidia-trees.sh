#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia_driver_branches_al2023, under /opt/nvidia/<branch>.
#
# Runs at build time only when nvidia_driver_trees_al2023 is on (off by default). So far it downloads and checks each
# branch's packages and removes them again. Nothing reads the trees yet: the native driver still runs the AMI.
set -Eeuo pipefail

if [[ ${NVIDIA_DRIVER_TREES:-false} != "true" ]]; then
    echo "build-nvidia-trees: skipping (NVIDIA_DRIVER_TREES=${NVIDIA_DRIVER_TREES:-false})"
    exit 0
fi

B=/opt/nvidia-build # scratch space for the build, removed at the end

step() {
    echo
    echo "=== $(date -u +%T) $*"
}
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# ==================================================================================================================
# Branches, flavors and versions
# ==================================================================================================================
# Packer passes nvidia_driver_branches_al2023 in order as "name=flavor,flavor" pairs; the first branch is the default,
# the natively installed driver. Each branch's full version is pinned in NVIDIA_DRIVER_VERSION, which check-update.sh
# keeps current: nvidia_driver_version_al2023 for the default branch, nvidia_driver_version_al2023_<name> for the others.

NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}

NAMES=()                         # branch names, in order; NAMES[0] is the default branch
declare -A FLAVORS=() VERSION=() # flavors and version of each branch, by name

# Read the branches: each "lts=open,proprietary,grid" pair adds "lts" to NAMES and "open proprietary grid" to
# FLAVORS[lts], keeping packer's order so the default branch comes first.
for pair in ${NVIDIA_DRIVER_BRANCHES:-}; do
    name=${pair%%=*}
    flavors=${pair#*=}
    NAMES+=("$name")
    FLAVORS[$name]=${flavors//,/ }
done
[[ ${#NAMES[@]} -gt 0 ]] || die "no branches in NVIDIA_DRIVER_BRANCHES"

# Read the versions: VERSION[lts] from nvidia_driver_version_al2023, VERSION[pb] from nvidia_driver_version_al2023_pb.
pin() { # pin KEY: the version NVIDIA_DRIVER_VERSION pins for KEY (exact key, so _al2023 doesn't match _al2023_pb)
    awk -F'"' -v k="$1" '$1 ~ "^" k " *= *$" {print $2}' "$NVIDIA_DRIVER_VERSION_FILE"
}
VERSION[${NAMES[0]}]=$(pin nvidia_driver_version_al2023)
for name in "${NAMES[@]:1}"; do
    VERSION[$name]=$(pin "nvidia_driver_version_al2023_$name")
done

# Check each branch: it needs a version and at least one flavor, every flavor must be open, proprietary or grid, and
# the branch is logged with what it builds.
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name' in $NVIDIA_DRIVER_VERSION_FILE"
    [[ -n ${FLAVORS[$name]} ]] || die "no kernel module flavors for branch '$name'"
    for flavor in ${FLAVORS[$name]}; do
        case $flavor in
        open | proprietary | grid) ;;
        *) die "branch $name: unknown flavor '$flavor'" ;;
        esac
    done
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

# ==================================================================================================================
# The packages each tree gets
# ==================================================================================================================
# The version-specific packages are the NVIDIA packages the native install put on the AMI at the default branch's
# version, so each tree has the same packages as the native install. They're unpacked into each tree instead of
# installed natively, because one host can't install two versions of the same package.

DEFAULT=${NAMES[0]}
sudo rm -rf "$B"

mapfile -t VS_NAMES < <(rpm -qa --qf '%{NAME} %{VERSION}\n' |
    awk -v v="${VERSION[$DEFAULT]}" '$2 == v && $1 !~ /^kmod-nvidia-/ {print $1}' | sort -u)
[[ ${#VS_NAMES[@]} -gt 0 ]] || die "no NVIDIA packages installed at ${VERSION[$DEFAULT]}"
echo "version-specific packages: ${#VS_NAMES[@]} (${VS_NAMES[*]})"

is_vs_name() {
    local n
    for n in "${VS_NAMES[@]}"; do [[ $n == "$1" ]] && return 0; done
    return 1
}

# ==================================================================================================================
# Download each branch's packages
# ==================================================================================================================
# For each branch: resolve and download its packages, drop copies at another branch's version, check that each
# package is there once, download the DKMS source packages it builds modules from, and check every signature.

download_branch() { # download_branch NAME
    local name=$1 v=${VERSION[$1]} dest=$B/dl/$1 n rpm nv ver flavor list out
    local specs=() kmods=()
    sudo mkdir -p "$dest" "$B/kmod/$name"

    # dnf download --resolve fetches the named packages plus the dependencies that aren't installed yet, such as
    # 595's egl-wayland2; those go into the tree with the rest. The versionlock plugin is off for the downloads
    # only: it holds the NVIDIA packages at the native install's version, and the other branches need theirs.
    for n in "${VS_NAMES[@]}"; do specs+=("$n-$v"); done
    sudo dnf -y download --resolve --disableplugin=versionlock --destdir="$dest" "${specs[@]}"

    # dnf satisfies the unversioned requirements between NVIDIA packages with the newest provider, so another
    # branch's copies of some version-specific packages get pulled in; drop those, and the DKMS packages it pulls in.
    shopt -s nullglob
    for rpm in "$dest"/*.rpm; do
        nv=$(rpm -qp --nosignature --qf '%{NAME} %{VERSION}' "$rpm") || die "cannot read $rpm"
        n=${nv% *}
        ver=${nv#* }
        if is_vs_name "$n" && [[ $ver != "$v" ]]; then
            echo "branch $name: dropping $(basename "$rpm"), version $ver"
            sudo rm -f "$rpm"
        fi
    done
    shopt -u nullglob
    sudo rm -f "$dest"/kmod-nvidia-*-dkms-*.rpm

    # Each package must be in the branch once: --resolve resolves each named package separately, so two of them can
    # pull in different versions of the same dependency.
    list=$(rpm -qp --nosignature --qf '  %{NAME} %{VERSION}\n' "$dest"/*.rpm | sort)
    echo "branch $name: packages:"
    echo "$list"
    n=$(awk '{print $1}' <<<"$list" | uniq -d | paste -sd' ')
    [[ -z $n ]] || die "branch $name: more than one version of $n"

    # The DKMS source packages: only the non-default branches build kernel modules (the default branch's are the
    # native install's). They conflict with each other, so they're downloaded without dependency resolution. The GRID
    # flavor comes from the GRID runfile, not a package.
    if [[ $name != "$DEFAULT" ]]; then
        for flavor in ${FLAVORS[$name]}; do
            case $flavor in
            open) kmods+=("kmod-nvidia-open-dkms-$v") ;;
            proprietary) kmods+=("kmod-nvidia-latest-dkms-$v") ;;
            esac
        done
    fi
    [[ ${#kmods[@]} -eq 0 ]] || sudo dnf -y download --disableplugin=versionlock --destdir="$B/kmod/$name" "${kmods[@]}"

    # dnf download checks the packages only against the repo metadata, which isn't signed (repo_gpgcheck=0), and the
    # packages are unpacked rather than installed, so no install transaction checks their signatures either. Each one
    # must be signed by a key the native install imported. rpmkeys exits 0 for an unsigned package, so the output is
    # matched.
    shopt -s nullglob
    local rpms=("$dest"/*.rpm "$B/kmod/$name"/*.rpm)
    shopt -u nullglob
    for rpm in "${rpms[@]}"; do
        out=$(rpmkeys --checksig "$rpm") || die "branch $name: $out"
        [[ $out == *"signatures OK" ]] || die "branch $name: not signed by an imported key: $out"
    done
    echo "branch $name: ${#rpms[@]} packages signed by an imported key"
}

for name in "${NAMES[@]}"; do
    step "download branch $name (${VERSION[$name]})"
    download_branch "$name"
done

# ==================================================================================================================
# Clean up
# ==================================================================================================================

sudo rm -rf "$B"
echo "build-nvidia-trees: done"
