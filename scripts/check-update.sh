#!/usr/bin/env bash
set -exo pipefail

usage() {
    echo "Usage:"
    echo "  $0 AMI_TYPE"
    echo "Example:"
    echo "  $0 al2"
    echo "AMI_TYPE Must be one of: al1, al2, al2023"
}

error() {
    local msg="$1"
    echo "ERROR: $msg"
    usage
    exit 1
}

# Function to handle NVIDIA driver version extraction and storage
handle_nvidia_version() {
    local ami_variant=$1
    local gpu_update=$2

    # Skip if not a GPU-supported AMI type
    if [[ $ami_variant != "al2" && $ami_variant != "al2023" ]]; then
        return
    fi

    local version=""
    local version_key="nvidia_driver_version_${ami_variant}"

    if [[ $gpu_update == true* ]]; then
        version=$(echo "$gpu_update" | cut -d' ' -f2)
    fi

    # Update version entry if version is available and file exists
    if [ -n "$version" ] && [ -f NVIDIA_DRIVER_VERSION ]; then
        if grep -q "^${version_key} = " NVIDIA_DRIVER_VERSION; then
            sed -i "s/^${version_key} = .*/${version_key} = \"${version}\"/" NVIDIA_DRIVER_VERSION
        fi
    fi
}

readonly ami_type="$1"
if [ -z "$ami_type" ]; then
    error "AMI_TYPE must be provided"
fi

cp release-$ami_type.auto.pkrvars.hcl release-$ami_type.old.hcl
./generate-release-vars.sh $ami_type
set +e
diff_val=$(diff <(grep -v ami_version release-$ami_type.old.hcl) <(grep -v ami_version release-$ami_type.auto.pkrvars.hcl))
set -e

# Check for NVIDIA driver version for both AL2 and AL2023
if [ "$ami_type" = "al2" ] || [ "$ami_type" = "al2023" ]; then
    gpu_update=$(./scripts/check-update-security.sh "${ami_type}_gpu")
    handle_nvidia_version "$ami_type" "$gpu_update"
    if [[ $gpu_update == true* ]]; then
        Update="true"
    fi
fi

# If no difference in dependencies, check for security update
if [ -z "$diff_val" ]; then
    Update="false"
    case "$ami_type" in
    "al1")
        Update=$(./scripts/check-update-security.sh $ami_type)
        ;;
    "al2" | "al2023")
        # Check security updates for each architecture type
        amd_update=$(./scripts/check-update-security.sh $ami_type)
        arm_update=$(./scripts/check-update-security.sh "${ami_type}_arm")

        # Combine results
        if [[ $amd_update == true* ]] || [[ $arm_update == true* ]]; then
            Update="true"
        fi
        ;;
    *)
        echo "Error: Invalid AMI type: $ami_type"
        exit 1
        ;;
    esac
else
    Update="true"
fi

rm "release-$ami_type.old.hcl"

if [ "$Update" = "true" ]; then
    echo "Update exists for $ami_type"
    git add release-$ami_type.auto.pkrvars.hcl
    if [ -f NVIDIA_DRIVER_VERSION ] && ! git diff --quiet NVIDIA_DRIVER_VERSION; then
        echo "NVIDIA driver version changes detected"
        git add NVIDIA_DRIVER_VERSION
    fi
else
    echo "Update does not exist for $ami_type"
fi
