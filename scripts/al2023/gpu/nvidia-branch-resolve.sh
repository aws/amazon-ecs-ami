#!/usr/bin/env bash
# Pick the NVIDIA driver branch for this instance, by the PCI device IDs of its GPUs, and write the branch name to
# /run/nvidia-driver-trees/branch for the later boot steps.
#
# The branch is the first one, the default branch first, whose open kernel modules support every attached NVIDIA GPU.
# If none does, as for GPUs only the proprietary flavor supports (P3's V100), it's the default branch. The lists come
# from build-nvidia-trees.sh's write_branch_files. lspci reads the GPUs from sysfs, which needs no network, so this
# can run early in boot. Nothing runs this yet: the AMI doesn't install it, and nvidia_driver_trees_al2023 is off by
# default.

# Stop on any failed command (-e), including one inside a pipeline (pipefail) or a function (-E), and on any unset
# variable (-u)
set -Eeuo pipefail

# The three directories, each overridable so tests can use temporary ones. The chosen branch goes under /run, which is
# cleared every boot, so the branch is picked again after a stop/start onto an instance type with another GPU.
CONFIG_DIR=${NVIDIA_TREES_CONFIG_DIR:-/etc/nvidia-driver-trees} # the branch lists the build wrote
TREES_DIR=${NVIDIA_TREES_DIR:-/opt/nvidia}                      # one driver tree per branch
RUN_DIR=${NVIDIA_TREES_RUN_DIR:-/run/nvidia-driver-trees}       # where the chosen branch is written

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# 1. Read the branch names, default first, and check each branch's GPU list. A malformed file fails this step rather
#    than sending the instance to the default branch.
[[ -f $CONFIG_DIR/nvidia-branches ]] || die "missing $CONFIG_DIR/nvidia-branches"
# NF is the number of words on a line: every line must be exactly one branch name
awk 'NF != 1 {exit 1}' "$CONFIG_DIR/nvidia-branches" || die "$CONFIG_DIR/nvidia-branches: want one branch name per line"
# Read the file into an array, one branch per element (-t drops each line's newline)
mapfile -t branches <"$CONFIG_DIR/nvidia-branches"
[[ ${#branches[@]} -gt 0 ]] || die "no branches in $CONFIG_DIR/nvidia-branches"
for branch in "${branches[@]}"; do
    device_list=$CONFIG_DIR/nvidia-devices-$branch
    [[ -f $device_list ]] || die "missing $device_list"
    # grep -v -x finds any whole line that isn't 4 lowercase hex digits; -q only reports whether there is one
    if grep -qvx '[0-9a-f]\{4\}' "$device_list"; then
        die "$device_list: want one 4-digit lowercase PCI device ID per line"
    fi
done

# 2. Read the PCI device ID of each attached NVIDIA GPU. lspci -d picks vendor 10de (NVIDIA) and class 0300 (VGA
#    controller, like G4dn's T4) or 0302 (3D controller, like P5's H100); -n prints IDs instead of names, and -mm one
#    quoted line per device, e.g. on G7:  2f:00.0 "0302" "10de" "2c3a" -ra1 "10de" "21f4"
#    awk takes the 4th field, the device ID, without its quotes ("2c3a" -> 2c3a).
mapfile -t gpu_device_ids < <({
    lspci -n -mm -d 10de::0300
    lspci -n -mm -d 10de::0302
} | awk '{gsub(/"/, "", $4); print $4}')

# 3. Pick the first branch whose list has every attached GPU, or the default branch if none does
chosen_branch=${branches[0]}
for branch in "${branches[@]}"; do
    supports_every_gpu=true
    for gpu_device_id in "${gpu_device_ids[@]}"; do
        # -x: the whole line must match, so "2c3a" doesn't match a longer ID
        grep -qx "$gpu_device_id" "$CONFIG_DIR/nvidia-devices-$branch" || supports_every_gpu=false
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
