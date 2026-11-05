#!/usr/bin/env bash
# Functions that build a per-version NVIDIA driver tree for each branch in nvidia_driver_branches_al2023, under
# /opt/nvidia/<branch>. install-nvidia-driver.sh sources this file and calls them after the native install, only when
# nvidia_driver_trees_al2023 is on (off by default). So far they download and check each branch's packages and remove
# them again. Nothing reads the trees yet: the native driver still runs the AMI.

TREES_BUILD_DIR=/opt/nvidia-build # scratch space for the build, removed at the end
NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}

step() {
    echo
    echo "=== $*"
}
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# read_driver_branches: fill NAMES, FLAVORS and VERSION from NVIDIA_DRIVER_BRANCHES and NVIDIA_DRIVER_VERSION.
#
# Packer passes nvidia_driver_branches_al2023 in order as "name=flavor,flavor" pairs; the first branch is the default,
# the natively installed driver. Each branch's full version is pinned in NVIDIA_DRIVER_VERSION, which check-update.sh
# keeps current: nvidia_driver_version_al2023 for the default branch, nvidia_driver_version_al2023_<name> for the
# others.
NAMES=()                         # branch names, in order; NAMES[0] is the default branch
declare -A FLAVORS=() VERSION=() # flavors and version of each branch, by name
read_driver_branches() {
    local pair name flavor
    # Each "lts=open,proprietary,grid" pair adds "lts" to NAMES and "open proprietary grid" to FLAVORS[lts], keeping
    # packer's order so the default branch comes first.
    for pair in ${NVIDIA_DRIVER_BRANCHES:-}; do
        name=${pair%%=*}
        NAMES+=("$name")
        FLAVORS[$name]=${pair#*=}
        FLAVORS[$name]=${FLAVORS[$name]//,/ }
    done
    [[ ${#NAMES[@]} -gt 0 ]] || die "no branches in NVIDIA_DRIVER_BRANCHES"

    # VERSION[lts] from nvidia_driver_version_al2023, VERSION[pb] from nvidia_driver_version_al2023_pb
    VERSION[${NAMES[0]}]=$(pinned_version nvidia_driver_version_al2023)
    for name in "${NAMES[@]:1}"; do
        VERSION[$name]=$(pinned_version "nvidia_driver_version_al2023_$name")
    done

    # Each branch needs a version and at least one flavor, and every flavor must be open, proprietary or grid
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
}
# pinned_version KEY: the version NVIDIA_DRIVER_VERSION pins for KEY, by exact key, so _al2023 doesn't match _al2023_pb
pinned_version() {
    awk -F'"' -v key="$1" '$1 ~ "^" key " *= *$" {print $2}' "$NVIDIA_DRIVER_VERSION_FILE"
}

# download_branch_packages NAME PACKAGE...: download branch NAME's version of the version-specific PACKAGEs, the
# DKMS source packages its flavors build from, and check every signature.
#
# Each branch's packages are downloaded in one dnf transaction, so dnf resolves them together and every dependency comes
# out at the branch's version, plus the other dependencies the host doesn't have yet (such as 595's egl-wayland2). The
# default branch's packages are the native install's, already installed, so they're downloaded with reinstall. The
# versionlock plugin is off for the downloads only: it holds the NVIDIA packages at the native install's version.
download_branch_packages() {
    local name=$1 version=${VERSION[$1]} download_dir=$TREES_BUILD_DIR/download/$1 dkms_dir=$TREES_BUILD_DIR/dkms/$1
    shift
    local package flavor rpm_file result action=install
    local package_specs=() dkms_packages=() rpm_files=()
    sudo mkdir -p "$download_dir" "$dkms_dir"

    for package in "$@"; do package_specs+=("$package-$version"); done
    if [[ $name == "${NAMES[0]}" ]]; then
        action=reinstall
    fi
    sudo dnf -y "$action" --downloadonly --downloaddir="$download_dir" --disableplugin=versionlock "${package_specs[@]}"

    # dnf has to resolve a kmod-nvidia-*-dkms package, since nvidia-kmod-common requires nvidia-kmod at the same version
    # and only those provide it, so they can't be excluded from the transaction. They're build inputs, downloaded per
    # flavor below, so the resolved copy is removed.
    sudo rm -f "$download_dir"/kmod-nvidia-*-dkms-*.rpm
    echo "branch $name: packages:"
    rpm -qp --nosignature --qf '  %{NAME} %{VERSION}\n' "$download_dir"/*.rpm | sort

    # The DKMS source packages each branch builds its kernel modules from, one per flavor it lists. They conflict with
    # each other, so they're downloaded without dependency resolution. The GRID flavor comes from the GRID runfile
    # instead.
    for flavor in ${FLAVORS[$name]}; do
        case $flavor in
        open) dkms_packages+=("kmod-nvidia-open-dkms-$version") ;;
        proprietary) dkms_packages+=("kmod-nvidia-latest-dkms-$version") ;;
        esac
    done
    [[ ${#dkms_packages[@]} -eq 0 ]] ||
        sudo dnf -y download --disableplugin=versionlock --destdir="$dkms_dir" "${dkms_packages[@]}"

    # dnf checks the packages only against the repo metadata, which isn't signed (repo_gpgcheck=0), and the packages are
    # unpacked rather than installed, so no install transaction checks their signatures either. Each one must be signed
    # by a key the native install imported. rpmkeys exits 0 for an unsigned package, so the output is matched.
    shopt -s nullglob
    rpm_files=("$download_dir"/*.rpm "$dkms_dir"/*.rpm)
    shopt -u nullglob
    for rpm_file in "${rpm_files[@]}"; do
        result=$(rpmkeys --checksig "$rpm_file") || die "branch $name: $result"
        [[ $result == *"signatures OK" ]] || die "branch $name: not signed by an imported key: $result"
    done
    echo "branch $name: ${#rpm_files[@]} packages signed by an imported key"
}
