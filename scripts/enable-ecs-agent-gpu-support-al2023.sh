#!/usr/bin/env bash
set -ex

if [[ $AMI_TYPE != "al2023"*"gpu" ]]; then
    exit 0
fi

# AL2023 GPU setup
sudo dnf install -y dkms kernel-modules-extra
sudo systemctl enable --now dkms

# nvidia-release creates an nvidia repo file at /etc/yum.repos.d/amazonlinux-nvidia.repo
# docker-runtime-nvidia is a custom Amazon Linux package that sets the gpu container runtime to nvidia
# instead of having to use 'nvidia-ctk runtime configure --runtime=docker'
sudo dnf install -y nvidia-release
sudo dnf install -y nvidia-driver \
    nvidia-fabric-manager \
    pciutils \
    xorg-x11-server-Xorg \
    nvidia-container-toolkit \
    docker-runtime-nvidia

sudo dnf install -y cuda

# The Fabric Manager service needs to be started and enabled on EC2 P4d instances
# in order to configure NVLinks and NVSwitches
sudo systemctl enable nvidia-fabricmanager

# NVIDIA Persistence Daemon needs to be started and enabled on P5 instances
# to maintain persistent software state in the NVIDIA driver.
sudo systemctl enable nvidia-persistenced

# Enable GPU support for ECS
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config
