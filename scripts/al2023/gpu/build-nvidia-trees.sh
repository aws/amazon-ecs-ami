#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia-branches, under /opt/nvidia/<branch>.
#
# Runs at build time only when nvidia_driver_trees is on (off by default). So far it reads and checks the branches and
# their versions. Nothing reads the trees yet: the natively installed driver still runs the AMI.
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
# The default branch's version is the pin the native install uses; the others come from nvidia_driver_tree_versions_al2023.
BRANCHES_FILE=${NVIDIA_BRANCHES_FILE:-/tmp/nvidia-branches}
NVIDIA_DRIVER_VERSION_FILE=${NVIDIA_DRIVER_VERSION_FILE:-/tmp/NVIDIA_DRIVER_VERSION}
declare -A VERSION=() FLAVORS=()
NAMES=()
while read -r name flavors; do
    [[ -z $name || $name == \#* ]] && continue
    NAMES+=("$name")
    FLAVORS[$name]=$flavors
done <"$BRANCHES_FILE"
[[ ${#NAMES[@]} -gt 0 ]] || die "no branches in $BRANCHES_FILE"
VERSION[${NAMES[0]}]=$(grep "^nvidia_driver_version_al2023" "$NVIDIA_DRIVER_VERSION_FILE" | awk -F'"' '{print $2}') || true
[[ -n ${VERSION[${NAMES[0]}]} ]] || die "no nvidia_driver_version_al2023 in $NVIDIA_DRIVER_VERSION_FILE"
for pair in ${NVIDIA_DRIVER_TREE_VERSIONS:-}; do
    VERSION[${pair%%=*}]=${pair#*=}
done
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name'"
    for flavor in ${FLAVORS[$name]}; do
        [[ $flavor == open || $flavor == proprietary || $flavor == grid ]] || die "branch $name: unknown flavor '$flavor'"
    done
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

echo "build-nvidia-trees: done"
