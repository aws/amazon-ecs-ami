#!/usr/bin/env bash
set -ex

if [[ $AMI_TYPE != "al2gpu" && $AMI_TYPE != "al2keplergpu" ]]; then
    exit 0
fi

GPG_CHECK=1
# don't do the gpg check in air-gapped regions
if [ -n "$AIR_GAPPED" ]; then
    GPG_CHECK=0
fi
tmpfile=$(mktemp)
cat >$tmpfile <<EOF
[amzn2-nvidia]
name=Amazon Linux 2 Nvidia repository
mirrorlist=\$awsproto://\$amazonlinux.\$awsregion.\$awsdomain/\$releasever/amzn2-nvidia/latest/\$basearch/mirror.list
priority=20
gpgcheck=$GPG_CHECK
gpgkey=https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub
enabled=1
exclude=libglvnd-*
EOF

# this repo is temporary and only used for installing the system-release-nvidia package
sudo mv $tmpfile /etc/yum.repos.d/amzn2-nvidia-tmp.repo
# system-release-nvidia creates an nvidia repo file at /etc/yum.repos.d/amzn2-nvidia.repo
sudo yum install -y system-release-nvidia
sudo rm /etc/yum.repos.d/amzn2-nvidia-tmp.repo

# for building AMIs for GPUs with Kepler architecture, fix package versions
# also exclude nvidia and cuda packages to update. Newer Nvidia drivers do not support Kepler architecture
# TODO: The package versions are fixed for Kepler. They have to be manually updated when there is a minor version update in AL repo.
if [[ $AMI_TYPE == "al2keplergpu" ]]; then
    sudo yum install -y kernel-devel-$(uname -r) \
        system-release-nvidia \
        nvidia-driver-latest-dkms-470.182.03 \
        nvidia-fabric-manager-470.182.03-1 \
        pciutils-3.5.1-2.amzn2 \
        xorg-x11-server-Xorg \
        docker-runtime-nvidia-1 \
        oci-add-hooks \
        libnvidia-container-1.4.0 \
        libnvidia-container-tools-1.4.0 \
        nvidia-container-runtime-hook-1.4.0

    sudo yum install -y cuda-toolkit-11-4
    echo "exclude=*nvidia* *cuda*" | sudo tee -a /etc/yum.conf
else
    # Default GPU AMI
    sudo yum install -y kernel-devel-$(uname -r) \
        system-release-nvidia \
        nvidia-driver-latest-dkms \
        nvidia-fabric-manager \
        pciutils \
        xorg-x11-server-Xorg \
        docker-runtime-nvidia \
        oci-add-hooks \
        libnvidia-container \
        libnvidia-container-tools \
        nvidia-container-runtime-hook

    sudo yum install -y cuda-drivers \
        cuda
fi
# The Fabric Manager service needs to be started and enabled on EC2 P4d instances
# in order to configure NVLinks and NVSwitches
sudo systemctl enable nvidia-fabricmanager
# NVIDIA Persistence Daemon needs to be started and enabled on P5 instances
# to maintain persistent software state in the NVIDIA driver.
sudo systemctl enable nvidia-persistenced
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config
