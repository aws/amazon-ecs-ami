#!/usr/bin/env bash
set -eo pipefail

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

readonly ami_type="$1"
if [ -z "$ami_type" ]; then
    error "AMI_TYPE must be provided"
fi

readonly ami_version=$(date +"%Y%m%d")

# this can be any region, as we use it to grab the latest AL2 AMI name so it should be the same across regions.
readonly region="us-west-2"

# Get the latest source AMI names (based on type)
case "$ami_type" in
"al1")
    # AL1
    ami_id_al1=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
    ami_name_al1=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al1" --query 'Images[0].Name' --output text)

    readonly ami_name_al1

    readonly ecs_version_al1=$(sed -n '/variable "ecs_version_al1" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly docker_version_al1=$(sed -n '/variable "docker_version_al1" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly exec_ssm_version=$(sed -n '/variable "exec_ssm_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')

    cat >|release-al1.auto.pkrvars.hcl <<EOF
ami_version_al1    = "$ami_version"
ecs_version_al1    = "$ecs_version_al1"
docker_version_al1 = "$docker_version_al1"
exec_ssm_version   = "$exec_ssm_version"
source_ami_al1     = "$ami_name_al1"
EOF
    ;;
"al2")
    # AL2
    ami_id_al2_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
    ami_name_al2_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_x86" --query 'Images[0].Name' --output text)
    ami_id_al2_arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs --query 'Parameters[0].[Value]' --output text)
    ami_name_al2_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_arm" --query 'Images[0].Name' --output text)
    ami_id_al2_kernel5dot10=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
    ami_name_al2_kernel5dot10=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_x86" --query 'Images[0].Name' --output text)
    ami_id_al2_kernel5dot10arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs --query 'Parameters[0].[Value]' --output text)
    ami_name_al2_kernel5dot10arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2_arm" --query 'Images[0].Name' --output text)

    readonly ami_name_al2_kernel5dot10arm ami_name_al2_kernel5dot10 ami_name_al2_arm ami_name_al2_x86

    readonly ecs_agent_version=$(sed -n '/variable "ecs_agent_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly ecs_init_rev=$(sed -n '/variable "ecs_init_rev" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly docker_version=$(sed -n '/variable "docker_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly containerd_version=$(sed -n '/variable "containerd_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly runc_version=$(sed -n '/variable "runc_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly exec_ssm_version=$(sed -n '/variable "exec_ssm_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')

    cat >|release-al2.auto.pkrvars.hcl <<EOF
ami_version_al2               = "$ami_version"
ecs_agent_version             = "$ecs_agent_version"
ecs_init_rev                  = "$ecs_init_rev"
docker_version                = "$docker_version"
containerd_version            = "$containerd_version"
runc_version                  = "$runc_version"
exec_ssm_version              = "$exec_ssm_version"
source_ami_al2                = "$ami_name_al2_x86"
source_ami_al2arm             = "$ami_name_al2_arm"
source_ami_al2kernel5dot10    = "$ami_name_al2_kernel5dot10"
source_ami_al2kernel5dot10arm = "$ami_name_al2_kernel5dot10arm"
EOF
    ;;
"al2023")
    # AL2023
    ami_id_al2023_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-x86_64 --query 'Parameters[0].[Value]' --output text)
    ami_name_al2023_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2023_x86" --query 'Images[0].Name' --output text)
    kernel_version_al2023_x86=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2023_x86")

    # AL2023 ARM
    ami_id_al2023_arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/al2023-ami-minimal-kernel-default-arm64 --query 'Parameters[0].[Value]' --output text)
    ami_name_al2023_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al2023_arm" --query 'Images[0].Name' --output text)
    kernel_version_al2023_arm=$(grep -o -e "-kernel-[1-9.]*" <<<"$ami_name_al2023_arm")

    readonly ami_name_al2023_x86 ami_name_al2023_arm

    readonly ecs_agent_version=$(sed -n '/variable "ecs_agent_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly ecs_init_rev=$(sed -n '/variable "ecs_init_rev" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly docker_version_al2023=$(sed -n '/variable "docker_version_al2023" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly containerd_version_al2023=$(sed -n '/variable "containerd_version_al2023" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly runc_version_al2023=$(sed -n '/variable "runc_version_al2023" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')
    readonly exec_ssm_version=$(sed -n '/variable "exec_ssm_version" {/,/}/p' variables.pkr.hcl | grep "default" | awk -F '"' '{ print $2 }')

    cat >|release-al2023.auto.pkrvars.hcl <<EOF
ami_version_al2023        = "$ami_version"
ecs_agent_version         = "$ecs_agent_version"
ecs_init_rev              = "$ecs_init_rev"
docker_version_al2023     = "$docker_version_al2023"
containerd_version_al2023 = "$containerd_version_al2023"
runc_version_al2023       = "$runc_version_al2023"
exec_ssm_version          = "$exec_ssm_version"
source_ami_al2023         = "$ami_name_al2023_x86"
source_ami_al2023arm      = "$ami_name_al2023_arm"
kernel_version_al2023     = "$kernel_version_al2023_x86"
kernel_version_al2023arm  = "$kernel_version_al2023_arm"
EOF
    ;;
*)
    error "Incorrect AMI Selection"
    ;;
esac
