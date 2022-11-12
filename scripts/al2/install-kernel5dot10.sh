#!/usr/bin/env bash
set -ex

if [[ $AMI_TYPE == "al2kernel5dot10" || $AMI_TYPE == "al2kernel5dot10arm" ]]; then
    sudo amazon-linux-extras install -y kernel-5.10
fi
