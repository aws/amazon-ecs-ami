#!/usr/bin/env bash
set -eio pipefail

usage() {
    echo "Usage:"
    echo "  $0 ECS_INIT_VERSION AMI_VERSION"
    echo "Example:"
    echo "  $0 1.55.0-1 20210902"
}

error() {
    local msg="$1"
    echo "ERROR: $msg"
    usage
    exit 1
}

readonly ecs_init_version="$1"
if [ -z "$ecs_init_version" ]; then
    error "ecs-init version is required."
fi
readonly ami_version="$2"
if [ -z "$ami_version" ]; then
    error "ami version is required."
fi

agent_version=$(echo "$ecs_init_version" | awk -F "-" '{ print $1 }')
ecs_init_rev=$(echo "$ecs_init_version" | awk -F "-" '{ print $2 }')
readonly agent_version ecs_init_rev
if [ -z "$ecs_init_rev" ]; then
    error "ecs-init rev was empty, did you forget the dash in ECS_INIT_VERSION? ie, 1.55.0-1"
fi
if [ -z "$agent_version" ]; then
    error "agent version was empty, seems that your ECS_INIT_VERSION was malformed, it should look like: 1.55.0-1"
fi

# this can be any region, as we use it to grab the latest AL2 AMI name so it should be the same across regions.
readonly region="us-west-2"

set -x

# Get the latest source AMI names
# AL1
ami_id_al1=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al1=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al1" --query 'Images[0].Name' --output text)

# AL2
ami_id_al2_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al2_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_x86" --query 'Images[0].Name' --output text)
ami_id_al2_arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al2_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_arm" --query 'Images[0].Name' --output text)
ami_id_al2_kernel5dot10=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al2_kernel5dot10=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_x86" --query 'Images[0].Name' --output text)
ami_id_al2_kernel5dot10arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al2_kernel5dot10arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_arm" --query 'Images[0].Name' --output text)

# AL2023
ami_id_al2023_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64 --query 'Parameters[0].[Value]' --output text)
ami_name_al2023_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2023_x86" --query 'Images[0].Name' --output text)
kernel_version_al2023_x86=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2023_x86")

# AL2023 ARM
ami_id_al2023_arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64 --query 'Parameters[0].[Value]' --output text)
ami_name_al2023_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2023_arm" --query 'Images[0].Name' --output text)
kernel_version_al2023_arm=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2023_arm")

# Get the latest AL2023 distribution release
# Ref: https://docs.aws.amazon.com/linux/al2023/ug/managing-repos-os-updates.html
# xmllint is required to find the latest distribution release from releasemd.xml in us-west-2
distribution_release_al2023=$(curl -s https://al2023-repos-us-west-2-de612dc2.s3.dualstack.us-west-2.amazonaws.com/core/releasemd.xml | xmllint --xpath "string(//root/releases/release[last()]/@version)" -)

readonly ami_name_al2_kernel5dot10arm ami_name_al2_kernel5dot10 ami_name_al2_arm ami_name_al2_x86 ami_name_al1 ami_name_al2023_arm ami_name_al2023_x86 distribution_release_al2023

cat >|release.auto.pkrvars.hcl <<EOF
ami_version          = "$ami_version"
ecs_agent_version    = "$agent_version"
ecs_init_rev         = "$ecs_init_rev"
docker_version       = "20.10.22"
containerd_version   = "1.6.19"
source_ami_al1       = "$ami_name_al1"
source_ami_al2       = "$ami_name_al2_x86"
source_ami_al2arm    = "$ami_name_al2_arm"
source_ami_al2kernel5dot10    = "$ami_name_al2_kernel5dot10"
source_ami_al2kernel5dot10arm = "$ami_name_al2_kernel5dot10arm"
source_ami_al2023    = "$ami_name_al2023_x86"
source_ami_al2023arm = "$ami_name_al2023_arm"
kernel_version_al2023    = "$kernel_version_al2023_x86"
kernel_version_al2023arm = "$kernel_version_al2023_arm"
distribution_release_al2023  = "$distribution_release_al2023"
EOF
