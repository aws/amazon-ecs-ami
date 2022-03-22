#!/usr/bin/env bash
set -ex

# install ssm (required until amazon-ssm-agent package is available in al2022 repos)
ARCH=$(uname -m)
case $ARCH in
'x86_64')
    sudo yum install -y "https://s3.us-west-2.amazonaws.com/amazon-ssm-us-west-2/latest/linux_amd64/amazon-ssm-agent.rpm"
    ;;
'aarch64')
    sudo yum install -y "https://s3.us-west-2.amazonaws.com/amazon-ssm-us-west-2/latest/linux_arm64/amazon-ssm-agent.rpm"
    ;;
esac
