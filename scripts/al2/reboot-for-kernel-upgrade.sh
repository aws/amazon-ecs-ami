#!/usr/bin/env bash
# TO-DO: Disable/remove this script once Amazon Linux team has released AL2 kernel 5.10 minimal AMIs.
set -ex

if [[ $AMI_TYPE == "al2kernel5dot10gpu" || $AMI_TYPE == "al2kernel5dot10inf" ]]; then
    sudo reboot
fi
