#!/usr/bin/env bash
set -ex

cat <<EOF | sudo tee -a /etc/amazon/efs/efs-utils.conf

[client-info]
source = ecs.ec2
EOF
