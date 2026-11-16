#!/usr/bin/env bash
# Pick the NVIDIA driver branch for this instance and write its name to /run/nvidia-driver-trees/branch.
#
# The branch is the first one, the default first, whose open kernel modules support every attached NVIDIA GPU, by PCI
# device ID. If none does, as for GPUs only the proprietary flavor supports (P3's V100), it's the default branch.
# build-nvidia-trees.sh writes the files this reads to /etc/nvidia-driver-trees: nvidia-branches has one branch name per
# line, the default first, and nvidia-devices-<branch> one PCI device ID per line. A line of any other shape fails the
# step rather than sending the instance to the default branch. lspci reads the device IDs from sysfs, which needs no
# network, so this can run early in boot. Nothing runs this yet: the AMI doesn't install it, and
# nvidia_driver_trees_al2023 is off by default.
set -Eeuo pipefail

CONF=${NVIDIA_TREES_CONF:-/etc/nvidia-driver-trees}
NV=${NVIDIA_TREES_DIR:-/opt/nvidia}
RUN=${NVIDIA_TREES_RUN:-/run/nvidia-driver-trees}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[[ -f $CONF/nvidia-branches ]] || die "missing $CONF/nvidia-branches"
awk 'NF != 1 {exit 1}' "$CONF/nvidia-branches" || die "$CONF/nvidia-branches: want one branch name per line"
mapfile -t branches <"$CONF/nvidia-branches"
[[ ${#branches[@]} -gt 0 ]] || die "no branches in $CONF/nvidia-branches"
for name in "${branches[@]}"; do
    [[ -f $CONF/nvidia-devices-$name ]] || die "missing $CONF/nvidia-devices-$name"
    grep -qvx '[0-9a-f]\{4\}' "$CONF/nvidia-devices-$name" &&
        die "$CONF/nvidia-devices-$name: want one 4-digit lowercase PCI device ID per line"
done

# The attached NVIDIA GPUs' device IDs: PCI vendor 10de, class 0300 (VGA controller, like G4dn's T4) or 0302 (3D
# controller, like P5's H100)
mapfile -t devices < <({
    lspci -n -mm -d 10de::0300
    lspci -n -mm -d 10de::0302
} | awk '{gsub(/"/, "", $4); print $4}')

branch=${branches[0]}
for name in "${branches[@]}"; do
    supported=true
    for device in "${devices[@]}"; do
        grep -qx "$device" "$CONF/nvidia-devices-$name" || supported=false
    done
    if [[ $supported == true ]]; then
        branch=$name
        break
    fi
done

[[ -d $NV/$branch ]] || die "no driver tree for branch $branch at $NV/$branch"
mkdir -p "$RUN"
echo "$branch" >"$RUN/branch"
echo "nvidia-branch-resolve: GPUs ${devices[*]:-none} -> $branch"
