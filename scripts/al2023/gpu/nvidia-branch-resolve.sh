#!/usr/bin/env bash
# Pick the NVIDIA driver branch for this instance and write its name to /run/nvidia-driver-trees/branch.
#
# The branch is the one nvidia-branch-families lists for the instance family, or the default branch (the first in
# nvidia-branches) for every other family. The instance type comes from DMI, which needs no network, so this can run
# early in boot. Nothing runs this yet: the AMI doesn't install it, and nvidia_driver_trees_al2023 is off by default.
set -Eeuo pipefail

CONF=${NVIDIA_TREES_CONF:-/etc/nvidia-driver-trees}
NV=${NVIDIA_TREES_DIR:-/opt/nvidia}
RUN=${NVIDIA_TREES_RUN:-/run/nvidia-driver-trees}
PRODUCT_NAME=${NVIDIA_DMI_PRODUCT_NAME:-/sys/devices/virtual/dmi/id/product_name}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

default=$(awk '$1 !~ /^#/ && NF {print $1; exit}' "$CONF/nvidia-branches")
[[ -n $default ]] || die "no branches in $CONF/nvidia-branches"

# On Nitro instances the DMI product name is the instance type, e.g. g7.2xlarge. On Xen instances (P3) it isn't, and
# they get the default branch.
itype=$(tr -d '[:space:]' <"$PRODUCT_NAME") || true
branch=$(awk -v f="${itype%%.*}" '$1 !~ /^#/ && $1 == f {print $2; exit}' "$CONF/nvidia-branch-families")
branch=${branch:-$default}

[[ -d $NV/$branch ]] || die "no driver tree for branch $branch at $NV/$branch"
mkdir -p "$RUN"
echo "$branch" >"$RUN/branch"
echo "nvidia-branch-resolve: ${itype:-unknown instance type} -> $branch"
