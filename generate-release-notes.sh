#!/bin/bash

set -eo pipefail

# Flags
AL2_GPU_NVIDIA_VERSION=""
AL2_GPU_CUDA_VERSION=""
AL1_CONTAINERD_VERSION=""
EXCLUDE_AMI=""

usage() {
    cat <<-EOF
Usage:
  $0

Options:
	--al2-gpu-nvidia-ver  (Optional) AL2 GPU NVIDIA version. If specified, then --al2-gpu-cuda-ver option is also required to be specified.
	--al2-gpu-cuda-ver    (Optional) AL2 GPU CUDA version. If specified, then  --al2-gpu-nvidia optin is also required to be specified.
	--al1-containerd-ver  (Optional) AL1 containerd version.
	--exclude-ami         (Optional) comma separated list of AMI variants that are excluded in the release.

Example:
  $0 --al2-gpu-nvidia-ver 000.00.00 --al2-gpu-cuda-ver 00.0.0 --al1-containerd-ver 0.0.0 --exclude-ami al2023neu,al2inf
EOF
}

main() {
    parse_args "$@"
    validate_args
    generate_release_notes
}

# Parses the options specified for the script.
parse_args() {
    while :; do
        case $1 in
        --al2-gpu-nvidia-ver)
            AL2_GPU_NVIDIA_VERSION="$2"
            shift
            ;;
        --al2-gpu-cuda-ver)
            AL2_GPU_CUDA_VERSION="$2"
            shift
            ;;
        --al1-containerd-ver)
            AL1_CONTAINERD_VERSION="$2"
            shift
            ;;
        --exclude-ami)
            EXCLUDE_AMI="$2"
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        --) # End of options.
            shift
            break
            ;;
        *) # Default case: No more options - break out of the loop.
            break ;;
        esac
        shift
    done
}

# Validates the options specified for the script.
validate_args() {
    if [ -z "$AL2_GPU_CUDA_VERSION" ] || [ -z "$AL2_GPU_NVIDIA_VERSION" ]; then
        if ! is_ami_excluded "al2gpu"; then
            printf "Error: AL2 GPU CUDA version or AL2 GPU NVIDIA version is empty when releasing AL2 GPU\n\n"
            usage
            exit 1
        fi
    fi
    if [ -z "$AL1_CONTAINERD_VERSION" ] && ! is_ami_excluded "al1"; then
        printf "Error: AL1 containerd version is empty when releasing AL1\n\n"
        usage
        exit 1
    fi
}

# Generates the relevant notes for the release.
generate_release_notes() {
    # Below file contains containerd version information for AL2023 and AL2 AMIs
    readonly variablespkr="variables.pkr.hcl"

    # Determine AMI version from pkrvars files
    placeholder_version="00000000"
    ami_version="$placeholder_version"
    readonly al2023pkrvars="release-al2023.auto.pkrvars.hcl"
    readonly al2pkrvars="release-al2.auto.pkrvars.hcl"
    readonly al1pkrvars="release-al1.auto.pkrvars.hcl"
    pkvars_files="$al2023pkrvars $al2pkrvars $al1pkrvars"
    for file in $pkvars_files; do
        file_ami_version=$(cat $file | grep -w 'ami_version' | cut -d '"' -f2)
        if [[ $file_ami_version -gt $ami_version ]]; then
            ami_version="$file_ami_version"
        fi
    done

    if [ "$ami_version" == "$placeholder_version" ]; then
        echo "Error: AMI version was not found in files $pkvars_files"
        exit 1
    fi

    # Prepare release notes
    release_notes="### Source AMI release notes
---
* [Amazon Linux 2023 release notes](https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes.html)
* [Amazon Linux 2 release notes](https://docs.aws.amazon.com/AL2/latest/relnotes/relnotes-al2.html)
* [Amazon Linux release notes](https://aws.amazon.com/amazon-linux-ami/2018.03-release-notes)

### Changelog
---
https://github.com/aws/amazon-ecs-ami/blob/main/CHANGELOG.md#$ami_version
"

    # AL2023
    if ! { is_ami_excluded "al2023" && is_ami_excluded "al2023arm" && is_ami_excluded "al2023neu"; }; then
        # Get AL2023 AMI family details
        readonly containerd_version_al2023=$(cat $variablespkr | sed -n '/containerd_version_al2023"/,/}/p' | grep -w 'default' | cut -d '"' -f2)
        readonly distribution_release_al2023=$(cat $al2023pkrvars | grep -w 'distribution_release_al2023' | cut -d '"' -f2)
        if [ -z "$containerd_version_al2023" ]; then
            echo "Error: Containerd version was not found for AL2023 in $al2023pkrvars"
            exit 1
        fi
        if [ -z "$distribution_release_al2023" ]; then
            echo "Error: Distribution release version was not found for AL2023 in $al2023pkrvars"
            exit 1
        fi

        # AL2023 Header
        al2023_header="
### Amazon ECS-optimized Amazon Linux 2023 AMI
---"
        release_notes="${release_notes}${al2023_header}"

        # Include AL2023 AMD64 release notes if there was an al2023 release
        if ! is_ami_excluded "al2023"; then
            # AL2023 AMD64 AMI details
            read ami_name_al2023_x86 agent_version_al2023_x86 docker_version_al2023_x86 source_ami_name_al2023_x86 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended")
            add_ami_to_release_notes "#### AMD64" "$ami_name_al2023_x86" "$agent_version_al2023_x86" "$docker_version_al2023_x86" "$containerd_version_al2023" "" "" "$source_ami_name_al2023_x86" "$distribution_release_al2023"
        fi

        # Include AL2023 ARM64 release notes if there was an al2023arm release
        if ! is_ami_excluded "al2023arm"; then
            # AL2023 ARM64 AMI details
            read ami_name_al2023_arm agent_version_al2023_arm docker_version_al2023_arm source_ami_name_al2023_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended")
            add_ami_to_release_notes "#### ARM64" "$ami_name_al2023_arm" "$agent_version_al2023_arm" "$docker_version_al2023_arm" "$containerd_version_al2023" "" "" "$source_ami_name_al2023_arm" "$distribution_release_al2023"
        fi

        # Include AL2023 Neuron release notes if there was an al2023neu release
        if ! is_ami_excluded "al2023neu"; then
            # AL2023 Neuron AMI details
            read ami_name_al2023_neuron agent_version_al2023_neuron docker_version_al2023_neuron source_ami_name_al2023_neuron <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/neuron/recommended")
            add_ami_to_release_notes "#### Neuron" "$ami_name_al2023_neuron" "$agent_version_al2023_neuron" "$docker_version_al2023_neuron" "$containerd_version_al2023" "" "" "$source_ami_name_al2023_neuron" "$distribution_release_al2023"
        fi
    fi

    # AL2
    if ! { is_ami_excluded "al2" && is_ami_excluded "al2arm" && is_ami_excluded "al2inf" && is_ami_excluded "al2gpu" &&
        is_ami_excluded "al2kernel5dot10" && is_ami_excluded "al2kernel5dot10arm"; }; then
        # Get AL2 AMI family details
        readonly containerd_version=$(cat $variablespkr | sed -n '/containerd_version"/,/}/p' | grep -w 'default' | cut -d '"' -f2)
        if [ -z "$containerd_version" ]; then
            echo "Error: Containerd version was not found in $variablespkr"
            exit 1
        fi

        # AL2 Header
        al2_header="
### Amazon ECS-optimized Amazon Linux 2 AMI
---"
        release_notes="${release_notes}${al2_header}"

        # Include AL2 AMD64 (Kernel 4.14) release notes if there was an al2 release
        if ! is_ami_excluded "al2"; then
            # AL2 AMD64 (Kernel 4.14) AMI details
            read ami_name_al2_x86 agent_version_al2_x86 docker_version_al2_x86 source_ami_name_al2_x86 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended")
            add_ami_to_release_notes "#### AMD64 (Kernel 4.14)" "$ami_name_al2_x86" "$agent_version_al2_x86" "$docker_version_al2_x86" "$containerd_version" "" "" "$source_ami_name_al2_x86" ""
        fi

        # Include AL2 ARM64 (Kernel 4.14) release notes if there was an al2arm release
        if ! is_ami_excluded "al2arm"; then
            # AL2 ARM64 (Kernel 4.14) AMI details
            read ami_name_al2_arm agent_version_al2_arm docker_version_al2_arm source_ami_name_al2_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended")
            add_ami_to_release_notes "#### ARM64 (Kernel 4.14)" "$ami_name_al2_arm" "$agent_version_al2_arm" "$docker_version_al2_arm" "$containerd_version" "" "" "$source_ami_name_al2_arm" ""
        fi

        # Include AL2 Neuron release notes if there was an al2inf release
        if ! is_ami_excluded "al2inf"; then
            # AL2 Neuron AMI details
            read ami_name_al2_inf agent_version_al2_inf docker_version_al2_inf source_ami_name_al2_inf <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/inf/recommended")
            add_ami_to_release_notes "#### Neuron (Kernel 4.14)" "$ami_name_al2_inf" "$agent_version_al2_inf" "$docker_version_al2_inf" "$containerd_version" "" "" "$source_ami_name_al2_inf" ""
        fi

        # Include AL2 GPU release notes if there was an al2gpu release
        if ! is_ami_excluded "al2gpu"; then
            # AL2 GPU AMI details
            read ami_name_al2_gpu agent_version_al2_gpu docker_version_al2_gpu source_ami_name_al2_gpu <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended")
            add_ami_to_release_notes "#### GPU (Kernel 4.14)" "$ami_name_al2_gpu" "$agent_version_al2_gpu" "$docker_version_al2_gpu" "$containerd_version" "$AL2_GPU_NVIDIA_VERSION" "$AL2_GPU_CUDA_VERSION" "$source_ami_name_al2_gpu" ""
        fi

        # Include AL2 AMD64 (Kernel 5.10) release notes if there was an al2kernel5dot10 release
        if ! is_ami_excluded "al2kernel5dot10"; then
            # AL2 AMD64 (Kernel 5.10) AMI details
            read ami_name_al2_kernel_5_10 agent_version_al2_kernel_5_10 docker_version_al2_kernel_5_10 source_ami_name_al2_kernel_5_10 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/kernel-5.10/recommended")
            add_ami_to_release_notes "#### AMD64 (Kernel 5.10)" "$ami_name_al2_kernel_5_10" "$agent_version_al2_kernel_5_10" "$docker_version_al2_kernel_5_10" "$containerd_version" "" "" "$source_ami_name_al2_kernel_5_10" ""
        fi

        # Include AL2 ARM64 (Kernel 5.10) release notes if there was an al2kernel5dot10arm release
        if ! is_ami_excluded "al2kernel5dot10arm"; then
            # AL2 ARM64 (Kernel 5.10) AMI details
            read ami_name_al2_kernel_5_10_arm agent_version_al2_kernel_5_10_arm docker_version_al2_kernel_5_10_arm source_ami_name_al2_kernel_5_10_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/kernel-5.10/arm64/recommended")
            add_ami_to_release_notes "#### ARM64 (Kernel 5.10)" "$ami_name_al2_kernel_5_10_arm" "$agent_version_al2_kernel_5_10_arm" "$docker_version_al2_kernel_5_10_arm" "$containerd_version" "" "" "$source_ami_name_al2_kernel_5_10_arm" ""
        fi
    fi

    # AL1
    # Include AL1 release notes if there was an al1 release
    if ! is_ami_excluded "al1"; then
        al1_header="
### Amazon ECS-optimized Amazon Linux AMI
---"
        release_notes="${release_notes}${al1_header}"

        read ami_name_al1 agent_version_al1 docker_version_al1 source_ami_name_al1 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux/recommended")
        add_ami_to_release_notes "The Amazon ECS-optimized Amazon Linux AMI is deprecated as of April 15, 2021. After that date, Amazon ECS will continue providing critical and important security updates for the AMI but will not add support for new features.
" "$ami_name_al1" "$agent_version_al1" "$docker_version_al1" "$AL1_CONTAINERD_VERSION" "" "" "$source_ami_name_al1" ""
    fi

    echo -n "$release_notes"
}

# Checks if a given AMI variant is excluded in the release.
is_ami_excluded() {
    local ami="$1"
    echo "$EXCLUDE_AMI" | grep -wq "$ami"
}

# Gets ECS Optimized AMI details from SSM parameter store given the parameter name.
# Uses the default AWS credentials as the parameter is public and can be
# fetched from a standard region (us-west-2 is used).
get_ami_details() {
    parameter_name=$1
    ami_details=$(aws ssm --region "us-west-2" get-parameters --names $parameter_name --query 'Parameters[0].Value' --output text | jq .)
    ami_name=$(echo "$ami_details" | jq -r '.image_name')
    agent_version=$(echo "$ami_details" | jq -r '.ecs_agent_version')
    docker_version=$(echo "$ami_details" | jq -r '.ecs_runtime_version' | awk '{print $3}')
    source_ami_name=$(echo "$ami_details" | jq -r '.source_image_name')
    echo "$ami_name $agent_version $docker_version $source_ami_name"
}

# Adds a given AMI variant to the release notes.
add_ami_to_release_notes() {
    local subheader="$1" # Optional (i.e., "" is allowed)
    local name="$2"
    local agent_ver="$3"
    local docker_ver="$4"
    local containerd_ver="$5"
    local nvidia_ver="$6" # Optional (i.e., "" is allowed)
    local cuda_ver="$7"   # Optional (i.e., "" is allowed)
    local source_name="$8"
    local dist_al2023_release="$9" # Optional (i.e., "" is allowed)

    if [ -n "$subheader" ]; then
        release_notes="${release_notes}
${subheader}"
    fi

    release_notes="${release_notes}
- AMI name: $name
- ECS Agent version: [$agent_ver](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_ver)
- Docker version: $docker_ver
- Containerd version: $containerd_ver"

    if [ -n "$nvidia_ver" ]; then
        release_notes="${release_notes}
- NVIDIA driver version: $nvidia_ver"
    fi

    if [ -n "$cuda_ver" ]; then
        release_notes="${release_notes}
- CUDA version: $cuda_ver"
    fi

    release_notes="${release_notes}
- Source AMI name: $source_name"

    if [ -n "$dist_al2023_release" ]; then
        release_notes="${release_notes}
- Distribution al2023 release: $dist_al2023_release"
    fi

    release_notes="${release_notes}
"
}

main "$@"
