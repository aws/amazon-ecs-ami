#!/usr/bin/env bash
set -ex

# The Fabric Manager service needs be started and enabled on EC2 P4d instances
# in order to configure NVLinks and NVSwitches
sudo systemctl enable nvidia-fabricmanager
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config
