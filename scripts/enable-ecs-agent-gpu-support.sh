#!/usr/bin/env bash
set -ex

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

sudo yum install -y nvidia-container-toolkit gcc kernel-devel-$(uname -r)

curl -O https://us.download.nvidia.com/tesla/525.85.12/NVIDIA-Linux-aarch64-525.85.12.run
chmod +x ./NVIDIA-Linux-aarch64-525.85.12.run
sudo ./NVIDIA-Linux-aarch64-525.85.12.run --silent

sudo nvidia-ctk runtime configure --runtime=docker

sudo systemctl restart docker

mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config
