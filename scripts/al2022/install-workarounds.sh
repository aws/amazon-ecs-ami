#!/usr/bin/env bash
set -ex

# update to AL2022 release that has latest repos
sudo dnf update -y --releasever=2022.0.20220202

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

# EFS install (this is required until efs-utils is available in al2022 repos)
sudo yum install -y git rpm-build make
git clone https://github.com/aws/efs-utils
cd efs-utils/
sudo make rpm
sudo yum install -y ./build/amazon-efs-utils*rpm

# workaround awslogs setup (this is only required for functional testing)

# install awscli plugin
sudo yum install -y "https://amazonlinux-2-repos-us-west-2.s3.us-west-2.amazonaws.com/blobstore/5eca0cad26ae5ee664f68fe00036ded0cb7637e544b6781f7502a22151b426f0/aws-cli-plugin-cloudwatch-logs-1.4.6-1.amzn2.0.1.noarch.rpm"
# install awslogs
sudo yum install -y "https://amazonlinux-2-repos-us-west-2.s3.us-west-2.amazonaws.com/blobstore/76a7b46358ac327a8f7094c431da285a93c8fae0d611515dbd7a2d0b129ae04a/awslogs-1.1.4-3.amzn2.noarch.rpm"
sudo yum install -y pip
pip install awscli-cwlogs
# copy the cwlogs python package from python2 to python3
sudo cp -r /usr/lib/python2.7/site-packages/cwlogs /usr/lib/python3.9/site-packages/
