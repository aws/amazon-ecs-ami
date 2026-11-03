#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia_driver_branches_al2023, under /opt/nvidia/<branch>.
#
# Runs at build time only when nvidia_driver_trees_al2023 is on (off by default). So far it reads and checks the
# branches and their versions. Nothing reads the trees yet: the natively installed driver still runs the AMI.
set -Eeuo pipefail

if [[ ${AMI_TYPE:-} != "al2023gpu" || ${NVIDIA_DRIVER_TREES:-false} != "true" ]]; then
    echo "build-nvidia-trees: skipping (AMI_TYPE=${AMI_TYPE:-}, NVIDIA_DRIVER_TREES=${NVIDIA_DRIVER_TREES:-false})"
    exit 0
fi

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

# Check the default branch lists all three flavors. It's the native install, which builds every flavor, and it serves
# every instance family that isn't mapped to another branch.
for flavor in open proprietary grid; do
    [[ " ${FLAVORS[${NAMES[0]}]} " == *" $flavor "* ]] || die "the default branch '${NAMES[0]}' must list the $flavor flavor"
done

echo "build-nvidia-trees: done"
