#!/usr/bin/env bash
set -ex

# Only proceed for AL2023 GPU AMIs
if [[ $AMI_TYPE != "al2023"*"gpu" ]]; then
    exit 0
fi

### Install GPU Drivers and Required Packages ###
# NVIDIA installation doc: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html#amazon-installation
# Amazon Linux 2023 repost: https://repost.aws/articles/ARwfQMxiC-QMOgWykD9mco1w/install-nvidia-gpu-driver-cuda-toolkit-nvidia-container-toolkit-on-amazon-ec2-instances-running-amazon-linux-2023-al2023

# Install base requirements
sudo dnf install -y dkms kernel-modules-extra-$(uname -r) kernel-devel-$(uname -r)

# Enable DKMS service
sudo systemctl enable --now dkms

# nvidia-release creates an nvidia repo file at /etc/yum.repos.d/amazonlinux-nvidia.repo
sudo dnf install -y nvidia-release

# Install NVIDIA drivers and tools
sudo dnf install -y nvidia-open \
    nvidia-fabric-manager \
    pciutils \
    xorg-x11-server-Xorg \
    nvidia-container-toolkit \
    nvidia-persistenced

### Package installation and setup to support P6 instances
# Install base requirements
sudo dnf install -y libibumad infiniband-diags nvlsm

# Load the User Mode API driver for InfiniBand
sudo modprobe ib_umad

# Ensure the ib_umad module is loaded at boot
echo ib_umad | sudo tee /etc/modules-load.d/ib_umad.conf

### Configure NVIDIA Services
# The Fabric Manager service needs to be started and enabled on EC2 P4d instances
# in order to configure NVLinks and NVSwitches
sudo systemctl enable nvidia-fabricmanager

# NVIDIA Persistence Daemon needs to be started and enabled on P5 instances
# to maintain persistent software state in the NVIDIA driver.
sudo systemctl enable nvidia-persistenced

### Configure ECS GPU Support
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config

### Configure GPU Container Runtime
# Create required directories
sudo mkdir -p /etc/docker-runtimes.d

# Create the NVIDIA runtime script
sudo tee /etc/docker-runtimes.d/nvidia <<'EOF'
#!/bin/sh
exec /usr/bin/nvidia-container-runtime "$@"
EOF

# Configure NVIDIA Container Runtime to use CDI mode
sudo nvidia-ctk config --in-place --set nvidia-container-runtime.mode=cdi

# Set appropriate file permissions
sudo chmod 755 /etc/docker-runtimes.d/nvidia