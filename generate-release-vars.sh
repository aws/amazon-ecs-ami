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

# AL2022
ami_id_al2022_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/al2022-ami-minimal-kernel-default-x86_64 --query 'Parameters[0].[Value]' --output text)
ami_name_al2022_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2022_x86" --query 'Images[0].Name' --output text)
kernel_version_al2022_x86=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2022_x86")

# AL2022 ARM (use describe-images for now until al2022 ARM SSM parameters are ready)
ami_id_al2022_arm=$(aws ec2 describe-images --region "$region" --owners amazon --filters "Name=name,Values=al2022-ami-minimal-2022.0.*" "Name=architecture,Values=arm64" --query "reverse(sort_by(Images, &CreationDate))[0].ImageId" --output text)
ami_name_al2022_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2022_arm" --query 'Images[0].Name' --output text)
kernel_version_al2022_arm=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2022_arm")

# Get the latest AL2022 distribution release
# xmllint is required to find the latest distribution release from releasemd.xml in us-west-2
distribution_release_al2022=$(curl -s https://al2022-repos-us-west-2-9761ab97.s3.dualstack.us-west-2.amazonaws.com/core/releasemd.xml | xmllint --xpath "string(//root/releases/release[last()]/@version)" -)

readonly ami_name_al2_arm ami_name_al2_x86 ami_name_al1 ami_name_al2022_arm ami_name_al2022_x86 distribution_release_al2022

cat >|release.auto.pkrvars.hcl <<EOF
ami_version          = "$ami_version"
ecs_agent_version    = "$agent_version"
ecs_init_rev         = "$ecs_init_rev"
docker_version       = "20.10.13"
containerd_version   = "1.4.13"
source_ami_al1       = "$ami_name_al1"
source_ami_al2       = "$ami_name_al2_x86"
source_ami_al2arm    = "$ami_name_al2_arm"
source_ami_al2022    = "$ami_name_al2022_x86"
source_ami_al2022arm = "$ami_name_al2022_arm"
kernel_version_al2022    = "$kernel_version_al2022_x86"
kernel_version_al2022arm = "$kernel_version_al2022_arm"
distribution_release_al2022  = "$distribution_release_al2022"
EOF
