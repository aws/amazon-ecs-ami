#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia-branches, under /opt/nvidia/<branch>.
#
# Runs at build time only when nvidia_driver_trees_al2023 is on (off by default). So far it downloads each branch's
# packages and removes them again. Nothing reads the trees yet: the natively installed driver still runs the AMI.
set -Eeuo pipefail

if [[ ${AMI_TYPE:-} != "al2023gpu" || ${NVIDIA_DRIVER_TREES:-false} != "true" ]]; then
    echo "build-nvidia-trees: skipping (AMI_TYPE=${AMI_TYPE:-}, NVIDIA_DRIVER_TREES=${NVIDIA_DRIVER_TREES:-false})"
    exit 0
fi

B=/opt/nvidia-build

step() {
    echo
    echo "=== $(date -u +%T) $*"
}
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# -------- branches and versions --------
# The default branch's version is the pin the native install uses; the others come from nvidia_driver_tree_versions_al2023.
BRANCHES_FILE=${NVIDIA_BRANCHES_FILE:-/tmp/nvidia-branches}
NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}
declare -A VERSION=() FLAVORS=()
NAMES=()
while read -r name flavors || [[ -n $name ]]; do
    [[ -z $name || $name == \#* ]] && continue
    NAMES+=("$name")
    FLAVORS[$name]=$flavors
done <"$BRANCHES_FILE"
[[ ${#NAMES[@]} -gt 0 ]] || die "no branches in $BRANCHES_FILE"
VERSION[${NAMES[0]}]=$(grep "^nvidia_driver_version_al2023" "$NVIDIA_DRIVER_VERSION_FILE" | awk -F'"' '{print $2}') || true
[[ -n ${VERSION[${NAMES[0]}]} ]] || die "no nvidia_driver_version_al2023 in $NVIDIA_DRIVER_VERSION_FILE"
for pair in ${NVIDIA_DRIVER_TREE_VERSIONS:-}; do
    [[ ${pair%%=*} != "${NAMES[0]}" ]] || die "nvidia_driver_tree_versions_al2023 can't pin the default branch ${NAMES[0]}"
    VERSION[${pair%%=*}]=${pair#*=}
done
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name'"
    for flavor in ${FLAVORS[$name]}; do
        [[ $flavor == open || $flavor == proprietary || $flavor == grid ]] || die "branch $name: unknown flavor '$flavor'"
    done
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

step "build prerequisites"
# Removed again at the end if they weren't on the AMI before, so the AMI's package set doesn't change.
PREREQS=()
rpm -q dnf-plugins-core >/dev/null || PREREQS+=(dnf-plugins-core)
[[ ${#PREREQS[@]} -eq 0 ]] || sudo dnf install -y "${PREREQS[@]}"
sudo rm -rf "$B"

# The version-specific packages are the NVIDIA packages the native install put on the AMI at the default branch's
# version, so each tree has the same packages as the native install. They're unpacked into each tree instead of
# installed natively, because one host can't install two versions of the same package. The DKMS source packages are
# build inputs, downloaded per flavor below.
mapfile -t VS_NAMES < <(rpm -qa --qf '%{NAME} %{VERSION}\n' |
    awk -v v="${VERSION[${NAMES[0]}]}" '$2 == v && $1 !~ /^kmod-nvidia-/ {print $1}' | sort -u)
[[ ${#VS_NAMES[@]} -gt 0 ]] || die "no NVIDIA packages installed at ${VERSION[${NAMES[0]}]}"
echo "version-specific packages: ${#VS_NAMES[@]} (${VS_NAMES[*]})"
is_vs_name() {
    local n
    for n in "${VS_NAMES[@]}"; do [[ $n == "$1" ]] && return 0; done
    return 1
}

# -------- download each branch's packages --------
# dnf download --resolve fetches the named packages plus the dependencies that aren't installed yet, such as 595's
# egl-wayland2; those go into the tree with the rest. It satisfies the unversioned requirements between NVIDIA packages
# with the newest provider, so another branch's copies of some version-specific packages get pulled in; drop those.
# The DKMS source packages conflict with each other, so they're downloaded separately, without dependency resolution,
# and only for the flavors the branch lists. The versionlock plugin is off for the downloads only: it holds the NVIDIA
# packages at the native install's version, and the other branches need theirs.
download_branch() { # download_branch NAME
    local name=$1 v=${VERSION[$1]} dest=$B/dl/$1 n rpm nv ver flavor
    sudo mkdir -p "$dest" "$B/kmod/$name"
    local specs=() kmods=()
    for n in "${VS_NAMES[@]}"; do specs+=("$n-$v"); done
    sudo dnf -y download --resolve --disableplugin=versionlock --destdir="$dest" "${specs[@]}"
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
    for flavor in ${FLAVORS[$name]}; do
        case $flavor in
        open) kmods+=("kmod-nvidia-open-dkms-$v") ;;
        proprietary) kmods+=("kmod-nvidia-latest-dkms-$v") ;;
        esac # grid comes from the GRID runfile, not a package
    done
    [[ ${#kmods[@]} -eq 0 ]] || sudo dnf -y download --disableplugin=versionlock --destdir="$B/kmod/$name" "${kmods[@]}"
}
for name in "${NAMES[@]}"; do
    step "download branch $name (${VERSION[$name]})"
    download_branch "$name"
done

sudo rm -rf "$B"
[[ ${#PREREQS[@]} -eq 0 ]] || sudo dnf -y remove "${PREREQS[@]}"
echo "build-nvidia-trees: done"
