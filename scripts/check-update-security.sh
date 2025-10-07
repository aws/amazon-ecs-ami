#!/usr/bin/env bash

set -exo pipefail

usage() {
    echo "Usage:"
    echo "  $0 AMI_PLATFORM"
    echo "Example:"
    echo "  $0 al2_arm"
    echo "AMI_PLATFORM Must be one of: al2, al2_arm, al2_gpu, al2023_gpu"
}

error_msg() {
    local msg="$1"
    echo "ERROR: $msg"
}

# Package to exclude when checking for security updates
EXCLUDE_SEC_UPDATES_PKGS="nvidia*,docker*,cuda*,containerd*,runc*"

# Paths to get the ami ids from ssm params
AL2_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
AL2_ARM_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2/arm64/recommended"
AL2_GPU_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2/gpu/recommended"
AL2023_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
AL2023_ARM_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended"
AL2023_GPU_PATH="/aws/service/ecs/optimized-ami/amazon-linux-2023/gpu/recommended"

# Indicates that an update exists
UPDATE_EXISTS_CODE="100"
# Indicates that a wait operation failed
WAIT_FAIL_CODE="255"
# Indicates success
SUCCESS_CODE="0"

# In case of failure, terminate instance
failure_cleanup() {
    terminate_out=$(aws ec2 terminate-instances --instance-ids $instance_id)
}

check_wait_response() {
    local wait_response=$1
    if [ "$wait_response" -eq "$WAIT_FAIL_CODE" ]; then
        error_msg "Failed to launch instance, instance timeout"
        exit 1
    fi
}

platform=$1
if [ -z "$platform" ]; then
    error_msg "Must specify an AMI platform"
    usage
    exit 1
fi
if [ -z "$IAM_INSTANCE_PROFILE_ARN" ]; then
    error_msg "IAM_INSTANCE_PROFILE_ARN environment variable must exist"
    exit 1
fi

# Get ecs-optimized ami's PATH in ssm parameters
platform=$1
instance_type="c5.large"
install_and_start_ssm_agent=0
case "$platform" in
"al2")
    ami_path=$AL2_PATH
    ;;
"al2_arm")
    ami_path=$AL2_ARM_PATH
    instance_type="c6g.medium"
    ;;
"al2_gpu")
    ami_path=$AL2_GPU_PATH
    ;;
"al2023")
    ami_path=$AL2023_PATH
    ;;
"al2023_arm")
    ami_path=$AL2023_ARM_PATH
    instance_type="c6g.medium"
    ;;
"al2023_gpu")
    ami_path=$AL2023_GPU_PATH
    instance_type="g4dn.xlarge"
    ;;
*)
    error_msg "Incorrect platform selection"
    usage
    exit 1
    ;;
esac

# Query ssm to get latest ecs optimized ami
ami_id=$(aws ssm get-parameters --names $ami_path --region us-west-2 | jq -r '.Parameters[0].Value' | jq -r '.image_id')

user_data=$(touch user_data.txt)
if [ "$install_and_start_ssm_agent" -eq 1 ]; then

    cat <<EOT >>user_data.txt
Content-Type: multipart/mixed; boundary="//"
MIME-Version: 1.0

--//
Content-Type: text/cloud-config; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="cloud-config.txt"

#cloud-config
repo_upgrade: none

--//
Content-Type: text/x-shellscript; charset="us-ascii"
MIME-Version: 1.0
Content-Transfer-Encoding: 7bit
Content-Disposition: attachment; filename="userdata.txt"

#!/bin/bash
cd /tmp
sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo start amazon-ssm-agent
--//--
EOT

else
    echo "#cloud-config" >>user_data.txt
    echo "repo_upgrade: none" >>user_data.txt
fi

# Launch ec2 instance with given ami and SSM access for command execution
# Also get instance id
# Modify user data to ignore automatic updates by al and al2
instance_id=$(aws ec2 run-instances \
    --image-id $ami_id \
    --instance-type $instance_type \
    --iam-instance-profile Arn=$IAM_INSTANCE_PROFILE_ARN \
    --metadata-options "HttpEndpoint=enabled,HttpTokens=required,HttpPutResponseHopLimit=2" \
    --user-data file://user_data.txt \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value='$platform-check-update-security'}]' |
    jq -r '.Instances[0].InstanceId')

# check-update based on platform
if [[ $platform == al2023* ]]; then
    check_upgrade_options="--sec-severity Critical --exclude=$EXCLUDE_SEC_UPDATES_PKGS"
    if [[ $platform == *gpu ]]; then
        check_upgrade_options="nvidia-driver-cuda"
    fi
    command_params="commands=[\"dnf --refresh check-upgrade --releasever=latest $check_upgrade_options -q\"]"
elif [ "$platform" = "al2_gpu" ]; then
    # The amzn2-nvidia repository does not provide updateinfo metadata (updateinfo.xml),
    # which YUM relies on to classify updates as security-related. The --security flag
    # would not detect updates without this metadata. Therefore, we check for all updates
    # to nvidia-driver packages and handle them as potential security updates.
    command_params='commands=["yum check-update nvidia-driver-latest-dkms -q"]'
else
    command_params="commands=[\"yum check-update --security --sec-severity=critical --exclude=$EXCLUDE_SEC_UPDATES_PKGS -q\"]"
fi

# Wait for instance status to reach ok, fail at timeout code
aws ec2 wait instance-running --instance-ids $instance_id
check_wait_response $(echo $?)

# Instance has been launched, terminate in case of an error
trap 'failure_cleanup' ERR

rm user_data.txt

# Assert that ssm agent is running before moving forward
ssm_agent_status() {
    aws ssm describe-instance-information \
        --instance-information-filter-list key=InstanceIds,valueSet=$instance_id \
        --query 'InstanceInformationList[0].PingStatus' --output text
}
max_retries=10
success=0
for ((r = 0; r < max_retries; r++)); do
    if [ "$(ssm_agent_status)" = "Online" ]; then
        success=1
        break
    fi
    sleep 10
done
if [ $success -ne 1 ]; then
    echo "SSM Agent connection timed out"
    failure_cleanup
    exit 1
fi

# Send command
cmd_id=$(aws ssm send-command \
    --document-name 'AWS-RunShellScript' \
    --parameters "$command_params" \
    --targets Key=instanceids,Values=$instance_id \
    --comment "run security check" |
    jq -r '.Command.CommandId')

# Wait for command to be executed
command_status() {
    aws ssm get-command-invocation \
        --command-id $cmd_id \
        --instance-id $instance_id \
        --query 'Status' \
        --output text
}
max_retries=25
success=0
for ((r = 0; r < max_retries; r++)); do
    sleep 5
    cmd_status=$(command_status)
    if [ "$cmd_status" = "Failed" ] || [ "$cmd_status" = "Success" ]; then
        success=1
        break
    fi
done
if [ $success -ne 1 ]; then
    echo "Command execution timed out"
    failure_cleanup
    exit 1
fi

# Get command output
cmd_output=$(aws ssm get-command-invocation \
    --command-id $cmd_id \
    --instance-id $instance_id)

cmd_response_code=$(echo "$cmd_output" | jq -r '.ResponseCode')
std_output=$(echo "$cmd_output" | jq -r '.StandardOutputContent')

# Delete the instance
terminate_out=$(aws ec2 terminate-instances --instance-ids $instance_id)

# Return whether update is necessary
if [ "$cmd_response_code" -eq "$UPDATE_EXISTS_CODE" ]; then
    if [ "$platform" = "al2_gpu" ]; then
        nvidia_driver_version=$(echo "$std_output" | grep "nvidia-driver-latest-dkms" | awk '{print $2}' | cut -d'-' -f1 | sed 's/^[0-9]://')
        if [ -n "$nvidia_driver_version" ]; then
            echo "true $nvidia_driver_version"
        else
            echo "true"
        fi
    elif [ "$platform" = "al2023_gpu" ]; then
        nvidia_driver_version=$(echo "$std_output" | grep "nvidia-driver-cuda" | awk '{print $2}' | cut -d'-' -f1 | sed 's/^[0-9]://')
        echo "true $nvidia_driver_version"
    else
        echo "true"
    fi
elif [ "$cmd_response_code" -ne "$SUCCESS_CODE" ]; then
    # If update doesn't exist and there was a fail code, something went wrong
    echo "Unknown issue with the command execution"
    exit 1
else
    echo "false"
fi

exit 0
