#!/bin/bash

set -eo pipefail

usage() {
    echo "Usage:"
    echo "  $0 AL2_GPU_NVIDIA_VERSION AL2_GPU_CUDA_VERSION AL1_CONTAINERD_VERSION"
    echo "Example:"
    echo "  $0 470.182.03 11.4 1.4.13"
}

# Parameters
al2_gpu_nvidia_version=$1
al2_gpu_cuda_version=$2
al1_containerd_version=$3

if [ "$al2_gpu_nvidia_version" == "" ]; then
    echo "Error: AL2 GPU NVIDIA version is empty"
    usage
    exit 1
fi
if [ "$al2_gpu_cuda_version" == "" ]; then
    echo "Error: AL2 GPU CUDA version is empty"
    usage
    exit 1
fi
if [ "$al1_containerd_version" == "" ]; then
    echo "Error: AL1 containerd version is empty"
    usage
    exit 1
fi

# Read some information from pkrvars file
ami_version=""
containerd_version_al2023=""
distribution_release_al2023=""
containerd_version=""
readonly pkrvars="release.auto.pkrvars.hcl"
while IFS='=' read -r key value; do
    # Remove leading and trailing whitespace, and quotes from the key and value
    key=$(echo "$key" | awk '{$1=$1};1')
    value=$(echo "$value" | awk '{$1=$1};1')
    value=${value//\"/} # strip quotes

    if [ "$key" == "ami_version" ]; then
        ami_version=$value
    fi
    if [ "$key" == "containerd_version_al2023" ]; then
        containerd_version_al2023=$value
    fi
    if [ "$key" == "distribution_release_al2023" ]; then
        distribution_release_al2023=$value
    fi
    if [ "$key" == "containerd_version" ]; then
        containerd_version=$value
    fi
done <$pkrvars

if [ "$ami_version" == "" ]; then
    echo "Error: AMI version was not found in $pkrvars"
    exit 1
fi
if [ "$containerd_version_al2023" == "" ]; then
    echo "Error: Containerd version was not found for AL2023 in $pkrvars"
    exit 1
fi
if [ "$distribution_release_al2023" == "" ]; then
    echo "Error: Distribution release version was not found for AL2023 in $pkrvars"
    exit 1
fi
if [ "$containerd_version" == "" ]; then
    echo "Error: Containerd version was not found in $pkrvars"
    exit 1
fi

# Gets ECS Optimized AMI details from SSM parameter store given the paramter name.
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

# AL2023 AMI details
read ami_name_al2023_x86 agent_version_al2023_x86 docker_version_al2023_x86 source_ami_name_al2023_x86 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended")
read ami_name_al2023_arm agent_version_al2023_arm docker_version_al2023_arm source_ami_name_al2023_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended")
read ami_name_al2023_neuron agent_version_al2023_neuron docker_version_al2023_neuron source_ami_name_al2023_neuron <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2023/neuron/recommended")

# AL2 AMI details
read ami_name_al2_x86 agent_version_al2_x86 docker_version_al2_x86 source_ami_name_al2_x86 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended")
read ami_name_al2_arm agent_version_al2_arm docker_version_al2_arm source_ami_name_al2_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended")
read ami_name_al2_gpu agent_version_al2_gpu docker_version_al2_gpu source_ami_name_al2_gpu <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended")
read ami_name_al2_inf agent_version_al2_inf docker_version_al2_inf source_ami_name_al2_inf <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/inf/recommended")
read ami_name_al2_kernel_5_10 agent_version_al2_kernel_5_10 docker_version_al2_kernel_5_10 source_ami_name_al2_kernel_5_10 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/kernel-5.10/recommended")
read ami_name_al2_kernel_5_10_arm agent_version_al2_kernel_5_10_arm docker_version_al2_kernel_5_10_arm source_ami_name_al2_kernel_5_10_arm <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux-2/kernel-5.10/arm64/recommended")

# AL1 AMI details
read ami_name_al1 agent_version_al1 docker_version_al1 source_ami_name_al1 <<<$(get_ami_details "/aws/service/ecs/optimized-ami/amazon-linux/recommended")

# Prepare release notes
release_notes="### Source AMI release notes
---
* [Amazon Linux 2023 release notes](https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes.html)
* [Amazon Linux 2 release notes](https://docs.aws.amazon.com/AL2/latest/relnotes/relnotes-al2.html)
* [Amazon Linux release notes](https://aws.amazon.com/amazon-linux-ami/2018.03-release-notes)

### Changelog
---
https://github.com/aws/amazon-ecs-ami/blob/main/CHANGELOG.md#$ami_version

### Amazon ECS-optimized Amazon Linux 2023 AMI
---
#### AMD64
- AMI name: $ami_name_al2023_x86
- ECS Agent version: [$agent_version_al2023_x86](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2023_x86)
- Docker version: $docker_version_al2023_x86
- Containerd version: $containerd_version_al2023
- Source AMI name: $source_ami_name_al2023_x86
- Distribution al2023 release: $distribution_release_al2023

#### ARM64
- AMI name: $ami_name_al2023_arm
- ECS Agent version: [$agent_version_al2023_arm](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2023_arm)
- Docker version: $docker_version_al2023_arm
- Containerd version: $containerd_version_al2023
- Source AMI name: $source_ami_name_al2023_arm
- Distribution al2023 release: $distribution_release_al2023

#### Neuron
- AMI name: $ami_name_al2023_neuron
- ECS Agent version: [$agent_version_al2023_neuron](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2023_neuron)
- Docker version: $docker_version_al2023_neuron
- Containerd version: $containerd_version_al2023
- Source AMI name: $source_ami_name_al2023_neuron
- Distribution al2023 release: $distribution_release_al2023

### Amazon ECS-optimized Amazon Linux 2 AMI
---
#### AMD64 (Kernel 4.14)
- AMI name: $ami_name_al2_x86
- ECS Agent version: [$agent_version_al2_x86](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_x86)
- Docker version: $docker_version_al2_x86
- Containerd version: $containerd_version
- Source AMI name: $source_ami_name_al2_x86

#### ARM64 (Kernel 4.14)
- AMI name: $ami_name_al2_arm
- ECS Agent version: [$agent_version_al2_arm](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_arm)
- Docker version: $docker_version_al2_arm
- Containerd version: $containerd_version
- Source AMI name: $source_ami_name_al2_arm

#### Neuron (Kernel 4.14)
- AMI name: $ami_name_al2_inf
- ECS Agent version: [$agent_version_al2_inf](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_inf)
- Docker version: $docker_version_al2_inf
- Containerd version: $containerd_version
- Source AMI name: $source_ami_name_al2_inf

#### GPU (Kernel 4.14)
- AMI name: $ami_name_al2_gpu
- ECS Agent version: [$agent_version_al2_gpu](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_gpu)
- Docker version: $docker_version_al2_gpu
- Containerd version: $containerd_version
- NVIDIA driver version: $al2_gpu_nvidia_version
- CUDA version: $al2_gpu_cuda_version
- Source AMI name: $source_ami_name_al2_gpu

#### AMD64 (Kernel 5.10)
- AMI name: $ami_name_al2_kernel_5_10
- ECS Agent version: [$agent_version_al2_kernel_5_10](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_kernel_5_10)
- Docker version: $docker_version_al2_kernel_5_10
- Containerd version: $containerd_version
- Source AMI name: $source_ami_name_al2_kernel_5_10

#### ARM64 (Kernel 5.10)
- AMI name: $ami_name_al2_kernel_5_10_arm
- ECS Agent version: [$agent_version_al2_kernel_5_10_arm](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al2_kernel_5_10_arm)
- Docker version: $docker_version_al2_kernel_5_10_arm
- Containerd version: $containerd_version
- Source AMI name: $source_ami_name_al2_kernel_5_10_arm

### Amazon ECS-optimized Amazon Linux AMI
---
The Amazon ECS-optimized Amazon Linux AMI is deprecated as of April 15, 2021. After that date, Amazon ECS will continue providing critical and important security updates for the AMI but will not add support for new features.

- AMI name: $ami_name_al1
- ECS Agent version: [$agent_version_al1](https://github.com/aws/amazon-ecs-agent/releases/tag/v$agent_version_al1)
- Docker version: $docker_version_al1
- Containerd version: $al1_containerd_version
- Source AMI name: $source_ami_name_al1"

echo "$release_notes"
