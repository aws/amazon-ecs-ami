#!/usr/bin/env bash
# Pick the NVIDIA driver branch for this instance, by the PCI device IDs of its GPUs, and write the branch name to
# /run/nvidia-driver-trees/branch for the later boot steps.
#
# The branch is the first one, the default branch first, whose open kernel modules support every attached NVIDIA GPU.
# If none does, as for GPUs only the proprietary flavor supports (P3's V100), it's the default branch. The lists come
# from build-nvidia-trees.sh's write_branch_files. lspci reads the GPUs from sysfs, which needs no network, so this
# can run early in boot. Nothing runs this yet: the AMI doesn't install it, and nvidia_driver_trees_al2023 is off by
# default.
set -Eeuo pipefail

CONF_DIR=${NVIDIA_TREES_CONF:-/etc/nvidia-driver-trees} # the build's branch lists
TREES_DIR=${NVIDIA_TREES_DIR:-/opt/nvidia}              # one driver tree per branch
RUN_DIR=${NVIDIA_TREES_RUN:-/run/nvidia-driver-trees}   # where the chosen branch is written

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# 1. Read the branch names, default first, and check each branch's GPU list. A malformed file fails this step rather
#    than sending the instance to the default branch.
[[ -f $CONF_DIR/nvidia-branches ]] || die "missing $CONF_DIR/nvidia-branches"
awk 'NF != 1 {exit 1}' "$CONF_DIR/nvidia-branches" || die "$CONF_DIR/nvidia-branches: want one branch name per line"
mapfile -t branches <"$CONF_DIR/nvidia-branches"
[[ ${#branches[@]} -gt 0 ]] || die "no branches in $CONF_DIR/nvidia-branches"
for branch in "${branches[@]}"; do
    device_list=$CONF_DIR/nvidia-devices-$branch
    [[ -f $device_list ]] || die "missing $device_list"
    if grep -qvx '[0-9a-f]\{4\}' "$device_list"; then
        die "$device_list: want one 4-digit lowercase PCI device ID per line"
    fi
done

# 2. Read the PCI device ID of each attached NVIDIA GPU: vendor 10de, class 0300 (VGA controller, like G4dn's T4) or
#    0302 (3D controller, like P5's H100). lspci -n -mm prints one line per device, with the device ID in field 4.
mapfile -t gpu_device_ids < <({
    lspci -n -mm -d 10de::0300
    lspci -n -mm -d 10de::0302
} | awk '{gsub(/"/, "", $4); print $4}')

# 3. Pick the first branch whose list has every attached GPU, or the default branch if none does
chosen_branch=${branches[0]}
for branch in "${branches[@]}"; do
    supports_every_gpu=true
    for gpu_device_id in "${gpu_device_ids[@]}"; do
        grep -qx "$gpu_device_id" "$CONF_DIR/nvidia-devices-$branch" || supports_every_gpu=false
    done
    if [[ $supports_every_gpu == true ]]; then
        chosen_branch=$branch
        break
    fi
done

# 4. Write the chosen branch for the later boot steps
[[ -d $TREES_DIR/$chosen_branch ]] || die "no driver tree for branch $chosen_branch at $TREES_DIR/$chosen_branch"
mkdir -p "$RUN_DIR"
echo "$chosen_branch" >"$RUN_DIR/branch"

# Logged so the boot journal shows which GPUs picked which branch, the first thing to check if an instance gets the
# wrong driver
echo "nvidia-branch-resolve: GPUs ${gpu_device_ids[*]:-none} -> $chosen_branch"
