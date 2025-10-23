#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage:"
    echo "  $0 AMI_TYPE"
    echo "Example:"
    echo "  $0 al2"
    echo "AMI_TYPE Must be one of: al2, al2023"
}

error() {
    local msg="$1"
    echo "ERROR: $msg"
    usage
    exit 1
}

# Function to handle NVIDIA driver and CUDA version extraction and storage
handle_nvidia_version() {
    local ami_variant=$1
    local gpu_update=$2

    # Skip if not a GPU-supported AMI type
    if [[ $ami_variant != "al2" && $ami_variant != "al2023" ]]; then
        return
    fi

    local nvidia_version=""
    local cuda_version=""
    local nvidia_version_key="nvidia_driver_version_${ami_variant}"
    local cuda_version_key="cuda_version_${ami_variant}"

    if [[ $gpu_update == true* ]]; then
        # Parse the output format: "true <nvidia_version> <cuda_version>" or "true <nvidia_version>" or "true cuda:<cuda_version>"
        local update_info=$(echo "$gpu_update" | cut -d' ' -f2-)

        # Check for both nvidia and cuda versions (space-separated)
        if [[ $update_info == *" "* ]]; then
            nvidia_version=$(echo "$update_info" | cut -d' ' -f1)
            cuda_version=$(echo "$update_info" | cut -d' ' -f2)
        # Check for cuda-only update
        elif [[ $update_info == cuda:* ]]; then
            cuda_version=$(echo "$update_info" | cut -d':' -f2)
        # else nvidia version
        else
            nvidia_version="$update_info"
        fi
    fi

    # Update NVIDIA driver version entry if available
    if [ -n "$nvidia_version" ]; then
        if grep -q "^${nvidia_version_key} = " NVIDIA_DRIVER_VERSION; then
            if ! sed -i "s/^${nvidia_version_key} = .*/${nvidia_version_key} = \"${nvidia_version}\"/" NVIDIA_DRIVER_VERSION; then
                echo "Failed to update NVIDIA driver version in NVIDIA_DRIVER_VERSION file"
            fi
        fi
    fi

    # Update CUDA version entry if available (AL2 only)
    if [ -n "$cuda_version" ] && [ "$ami_variant" = "al2" ]; then
        if grep -q "^${cuda_version_key} = " NVIDIA_DRIVER_VERSION; then
            if ! sed -i "s/^${cuda_version_key} = .*/${cuda_version_key} = \"${cuda_version}\"/" NVIDIA_DRIVER_VERSION; then
                echo "Failed to update CUDA version in NVIDIA_DRIVER_VERSION file"
            fi
        fi
    fi
}

readonly ami_type="${1:-}"
if [ -z "$ami_type" ]; then
    error "AMI_TYPE must be provided"
fi

# Validate AMI type
case "$ami_type" in
al2 | al2023)
    # Valid AMI types
    ;;
*)
    error "Invalid AMI type: $ami_type"
    ;;
esac

# Backup current release file and generate new one
cp release-$ami_type.auto.pkrvars.hcl release-$ami_type.old.hcl
./generate-release-vars.sh $ami_type

# Compare release files (excluding ami_version)
set +e
diff_val=$(diff <(grep -v ami_version release-$ami_type.old.hcl) <(grep -v ami_version release-$ami_type.auto.pkrvars.hcl))
set -e

# Initialize update flag
Update="false"

# Check for NVIDIA driver version updates
gpu_update=$(./scripts/check-update-security.sh "${ami_type}_gpu")
handle_nvidia_version "$ami_type" "$gpu_update"
# Only trigger update if GPU update detected AND NVIDIA_DRIVER_VERSION file actually changed
if [[ $gpu_update == true* ]] && ! git diff --quiet NVIDIA_DRIVER_VERSION; then
    Update="true"
fi

# Check for security updates if no dependency changes
if [ -z "$diff_val" ]; then
    # Check security updates for each architecture type
    amd_update=$(./scripts/check-update-security.sh $ami_type)
    arm_update=$(./scripts/check-update-security.sh "${ami_type}_arm")

    # Combine results
    if [[ $amd_update == true* ]] || [[ $arm_update == true* ]]; then
        Update="true"
    fi
else
    Update="true"
fi

# Clean up temporary file
rm "release-$ami_type.old.hcl"

# Handle git operations based on update status
if [ "$Update" = "true" ]; then
    echo "Update exists for $ami_type"
    git add release-$ami_type.auto.pkrvars.hcl

    # Add NVIDIA_DRIVER_VERSION if it has changes
    if ! git diff --quiet NVIDIA_DRIVER_VERSION; then
        echo "NVIDIA driver version changes detected"
        git add NVIDIA_DRIVER_VERSION
    fi
else
    echo "Update does not exist for $ami_type"
fi
