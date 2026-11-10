#!/usr/bin/env bash
# Pick the NVIDIA driver branch for this instance and write its name to /run/nvidia-driver-trees/branch.
#
# The branch is the one nvidia-branch-families lists for the instance family, or the default branch for every other
# family. build-nvidia-trees.sh writes both files to /etc/nvidia-driver-trees from nvidia_driver_branches_al2023 and
# nvidia_driver_branch_families_al2023: nvidia-branches has one branch name per line, the default first, and
# nvidia-branch-families has one "<family> <branch>" line per family. A line of any other shape fails the step rather
# than sending the instance to the default branch. The instance type comes from DMI, which needs no network, so this
# can run early in boot. Nothing runs this yet: the AMI doesn't install it, and nvidia_driver_trees_al2023 is off by
# default.
set -Eeuo pipefail

CONF=${NVIDIA_TREES_CONF:-/etc/nvidia-driver-trees}
NV=${NVIDIA_TREES_DIR:-/opt/nvidia}
RUN=${NVIDIA_TREES_RUN:-/run/nvidia-driver-trees}
PRODUCT_NAME=${NVIDIA_DMI_PRODUCT_NAME:-/sys/devices/virtual/dmi/id/product_name}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

for f in nvidia-branches nvidia-branch-families; do
    [[ -f $CONF/$f ]] || die "missing $CONF/$f"
done
awk 'NF != 1 {exit 1}' "$CONF/nvidia-branches" || die "$CONF/nvidia-branches: want one branch name per line"
awk 'NF != 2 {exit 1}' "$CONF/nvidia-branch-families" ||
    die "$CONF/nvidia-branch-families: want one \"<family> <branch>\" line per family"

default=$(awk 'NR == 1 {print $1}' "$CONF/nvidia-branches")
[[ -n $default ]] || die "no branches in $CONF/nvidia-branches"

# On Nitro instances the DMI product name is the instance type, e.g. g7.2xlarge. EC2 doesn't document this (its
# docs cover board_asset_tag, the instance ID), but it matched IMDS on g7.2xlarge and g4dn.xlarge. On Xen instances
# (P3) it isn't the instance type, and they get the default branch.
itype=$(tr -d '[:space:]' <"$PRODUCT_NAME") || true
branch=$(awk -v f="${itype%%.*}" '$1 == f {print $2; exit}' "$CONF/nvidia-branch-families")
branch=${branch:-$default}

[[ -d $NV/$branch ]] || die "no driver tree for branch $branch at $NV/$branch"
mkdir -p "$RUN"
echo "$branch" >"$RUN/branch"
echo "nvidia-branch-resolve: ${itype:-unknown instance type} -> $branch"
