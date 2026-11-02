#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia-branches, under /opt/nvidia/<branch>.
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

# -------- branches and versions --------
# Each branch's version is pinned in NVIDIA_DRIVER_VERSION: the default branch's by nvidia_driver_version_al2023, the
# pin the native install uses, and every other branch's by nvidia_driver_version_al2023_<branch>.
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
pin() { # pin KEY: the version NVIDIA_DRIVER_VERSION pins for KEY
    awk -F'"' -v k="$1" '$1 ~ "^" k " *= *$" {print $2}' "$NVIDIA_DRIVER_VERSION_FILE"
}
VERSION[${NAMES[0]}]=$(pin nvidia_driver_version_al2023)
for name in "${NAMES[@]:1}"; do
    VERSION[$name]=$(pin "nvidia_driver_version_al2023_$name")
done
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name' in $NVIDIA_DRIVER_VERSION_FILE"
    for flavor in ${FLAVORS[$name]}; do
        [[ $flavor == open || $flavor == proprietary || $flavor == grid ]] || die "branch $name: unknown flavor '$flavor'"
    done
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

echo "build-nvidia-trees: done"
