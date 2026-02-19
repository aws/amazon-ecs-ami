#!/usr/bin/env bash
set -ex

# Only proceed for AL2023 GPU AMIs
if [[ $AMI_TYPE != "al2023"*"gpu" ]]; then
    exit 0
fi

# Set executable permissions and move kmod utils to /usr/bin
# kmod utilities are copied to /tmp by Packer
sudo chmod +x "/tmp/kmod-util"
sudo mv "/tmp/kmod-util" /usr/bin/

# Configure DKMS for parallel compilation to reduce NVIDIA driver build time
# This optimization enables multi-threaded compilation using all available CPU cores,
sudo mkdir -p /etc/dkms
echo "MAKE[0]=\"'make' -j$(nproc --all) modules\"" | sudo tee /etc/dkms/nvidia.conf

### Base System Preparation ###
# Install kernel development packages for current running kernel
RUNNING_KERNEL=$(uname -r)
sudo dnf install -y \
  "dnf-command(versionlock)" \
  "kernel-devel-${RUNNING_KERNEL}" \
  "kernel-headers-${RUNNING_KERNEL}" \
  "kernel-modules-extra-${RUNNING_KERNEL}" \
  "kernel-modules-extra-common-${RUNNING_KERNEL}" \
  dkms

# Lock kernel version to prevent automatic updates that could break DKMS modules
sudo dnf versionlock 'kernel*'

# Enable DKMS service
sudo systemctl enable --now dkms

# nvidia-release creates an nvidia repo file at /etc/yum.repos.d/amazonlinux-nvidia.repo
sudo dnf install -y nvidia-release

# Temporary fix: ISO regions cannot use dualstack URLs, remove them from the repo file
if [ -n "$AIR_GAPPED" ]; then
    sudo sed -i 's/\$dualstack//g' /etc/yum.repos.d/amazonlinux-nvidia.repo
fi

### Kernel Module Archive Functions ###
# These functions pre-compile and archive different NVIDIA driver variants
# This allows runtime switching between proprietary, open-source, and GRID drivers
# without rebuilding modules each time

# Build and archive proprietary NVIDIA driver
function archive-proprietary-kmod() {
  sudo dnf -y install "kmod-nvidia-latest-dkms"

  NVIDIA_PROPRIETARY_VERSION=$(kmod-util module-version nvidia)
  sudo dkms remove "nvidia/$NVIDIA_PROPRIETARY_VERSION" --all

  # Rename to avoid conflicts with other driver variants
  sudo sed -i 's/PACKAGE_NAME="nvidia"/PACKAGE_NAME="nvidia-proprietary"/' /usr/src/nvidia-$NVIDIA_PROPRIETARY_VERSION/dkms.conf
  sudo mv /usr/src/nvidia-$NVIDIA_PROPRIETARY_VERSION /usr/src/nvidia-proprietary-$NVIDIA_PROPRIETARY_VERSION

  # Build and install the renamed module
  sudo dkms add -m nvidia-proprietary -v $NVIDIA_PROPRIETARY_VERSION
  sudo dkms build -m nvidia-proprietary -v $NVIDIA_PROPRIETARY_VERSION
  sudo dkms install -m nvidia-proprietary -v $NVIDIA_PROPRIETARY_VERSION

  # Archive for later use and clean up
  sudo kmod-util archive nvidia-proprietary
  sudo kmod-util remove nvidia-proprietary
  sudo rm -rf /usr/src/nvidia-proprietary*
  sudo dnf -y remove --all "kmod-nvidia-latest-dkms*"
}

# Build and archive open-source NVIDIA driver
function archive-open-kmod() {
  sudo dnf -y install "kmod-nvidia-open-dkms"
  
  NVIDIA_OPEN_VERSION=$(kmod-util module-version nvidia)
  sudo kmod-util archive nvidia

# Prepare source for GRID driver variant (shares same base)
  sudo mkdir /usr/src/nvidia-grid-$NVIDIA_OPEN_VERSION
  sudo cp -R /usr/src/nvidia-$NVIDIA_OPEN_VERSION/* /usr/src/nvidia-grid-$NVIDIA_OPEN_VERSION

  sudo kmod-util remove nvidia
}

# Build and archive GRID driver
function archive-grid-kmod() {
  NVIDIA_OPEN_VERSION=$(ls -d /usr/src/nvidia-grid-* | sed 's/.*nvidia-grid-//')

  # Rename the DKMS package to avoid conflicts with other driver variants
  sudo sed -i 's/PACKAGE_NAME="nvidia"/PACKAGE_NAME="nvidia-grid"/g' /usr/src/nvidia-grid-$NVIDIA_OPEN_VERSION/dkms.conf

  # Enable GRID-specific build flags for virtualization support
  # Ref for build flags: https://github.com/NVIDIA/open-gpu-kernel-modules/blob/2b436058a616676ec888ef3814d1db6b2220f2eb/kernel-open/conftest.sh#L34-L35
  sudo sed -i "s/MAKE\[0\]=\"'make'/MAKE\[0\]=\"'make' GRID_BUILD=1 GRID_BUILD_CSP=1 /g" /usr/src/nvidia-grid-$NVIDIA_OPEN_VERSION/dkms.conf

  sudo dkms build -m nvidia-grid -v $NVIDIA_OPEN_VERSION
  sudo dkms install nvidia-grid/$NVIDIA_OPEN_VERSION
  
  # Archive and clean up
  sudo kmod-util archive nvidia-grid
  sudo kmod-util remove nvidia-grid
  sudo rm -rf /usr/src/nvidia*
}

### Build All Driver Variants ###
# Pre-compile and archive all three driver types for runtime flexibility
archive-proprietary-kmod
archive-open-kmod
archive-grid-kmod

### Install GPU Drivers and Required Packages ###
# NVIDIA installation doc: https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/index.html#amazon-installation
# Amazon Linux 2023 repost: https://repost.aws/articles/ARwfQMxiC-QMOgWykD9mco1w/install-nvidia-gpu-driver-cuda-toolkit-nvidia-container-toolkit-on-amazon-ec2-instances-running-amazon-linux-2023-al2023
sudo dnf install -y nvidia-open \
    nvidia-fabric-manager \
    pciutils \
    xorg-x11-server-Xorg \
    nvidia-container-toolkit \
    nvidia-persistenced

# Lock NVIDIA packages to prevent automatic updates
# Updates can break compatibility between driver and kernel modules
sudo dnf versionlock 'nvidia*' 'kmod*' 'libnvidia*'

### P6 Instance Support ###
# Install base requirements
sudo dnf install -y libibumad infiniband-diags nvlsm

# Load the User Mode API driver for InfiniBand
sudo modprobe ib_umad

# Ensure the ib_umad module is loaded at boot
echo ib_umad | sudo tee /etc/modules-load.d/ib_umad.conf


### Dynamic Driver Loading Setup ###
# Install boot-time service that detects GPU hardware and loads the right driver
# This service runs early in boot to ensure the correct driver is loaded before applications start
sudo mv /tmp/nvidia-kmod-load.sh /etc/ecs/
sudo mv /tmp/nvidia-kmod-load.service /etc/systemd/system/nvidia-kmod-load.service
sudo systemctl daemon-reload
sudo systemctl enable nvidia-kmod-load.service

### NVIDIA Service Configuration ###
# The Fabric Manager service needs to be started and enabled on EC2 P4d instances
# in order to configure NVLinks and NVSwitches
sudo systemctl enable nvidia-fabricmanager

# NVIDIA Persistence Daemon needs to be started and enabled on P5 instances
# to maintain persistent software state in the NVIDIA driver.
sudo systemctl enable nvidia-persistenced

### Cleanup Build-Time Configuration ###
# Remove the hardcoded DKMS configuration to prevent it from being baked into the AMI
sudo rm -f /etc/dkms/nvidia.conf
