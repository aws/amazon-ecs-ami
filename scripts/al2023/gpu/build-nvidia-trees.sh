#!/usr/bin/env bash
# Build a per-version NVIDIA driver tree for each branch in nvidia_driver_versions_al2023, under /opt/nvidia/<branch>.
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
# Packer passes nvidia_driver_versions_al2023 and nvidia_driver_flavors_al2023 as "name=value" pairs. The default
# branch, the native install's, comes first; the others follow in name order.
DEFAULT=${NVIDIA_DRIVER_DEFAULT_BRANCH:-}
[[ -n $DEFAULT ]] || die "NVIDIA_DRIVER_DEFAULT_BRANCH is not set"
declare -A VERSION=() FLAVORS=()
for pair in ${NVIDIA_DRIVER_VERSIONS:-}; do
    VERSION[${pair%%=*}]=${pair#*=}
done
for pair in ${NVIDIA_DRIVER_FLAVORS:-}; do
    flavors=${pair#*=}
    FLAVORS[${pair%%=*}]=${flavors//,/ }
done
[[ -n ${VERSION[$DEFAULT]:-} ]] || die "no driver version for the default branch '$DEFAULT'"
NAMES=("$DEFAULT")
while read -r name; do
    [[ $name == "$DEFAULT" ]] || NAMES+=("$name")
done < <(printf '%s\n' "${!VERSION[@]}" "${!FLAVORS[@]}" | sort -u)
for name in "${NAMES[@]}"; do
    [[ -n ${VERSION[$name]:-} ]] || die "no driver version for branch '$name'"
    [[ -n ${FLAVORS[$name]:-} ]] || die "no kernel module flavors for branch '$name'"
    for flavor in ${FLAVORS[$name]}; do
        [[ $flavor == open || $flavor == proprietary || $flavor == grid ]] || die "branch $name: unknown flavor '$flavor'"
    done
    echo "branch $name: ${VERSION[$name]} (flavors: ${FLAVORS[$name]})"
done

echo "build-nvidia-trees: done"
