#!/usr/bin/env bash
# TO-DO once Amazon Linux team has released AL2 kernel 5.10 minimal AMIs:
#   - Disable/remove this script
#   - Modify AL2 kernel 5.10 variables in generate-release-vars.sh to use SSM parameters of AL2 kernel 5.10 minimal AMIs
set -ex

if [[ $AMI_TYPE == "al2kernel5dot10" || $AMI_TYPE == "al2kernel5dot10arm" ]]; then
    sudo amazon-linux-extras install -y kernel-5.10
    sudo rpm -e kernel-4.*
fi
