#!/usr/bin/env bash
set -ex

if test $AMI_TYPE != "al2gpu" && test $AMI_TYPE != "al2armgpu"; then
    exit 0
fi

# Installation procedure:
# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html

# Select a version you like
# https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/platform-support.html
NVIDIA_DRIVERS_VERSION="525.85.12"

# System dependencies so NVIDIA drivers can be installed correctly
sudo yum install -y \
  kernel-devel-$(uname -r) \
  pciutils \
  xorg-x11-server-Xorg \
  libglvnd \
  libglvnd-devel \
  vulkan

# Install custom version of the NVIDIA drivers
# The GPUs aren't enabled by default since x11 config is missing
# --silent answer all questions with default values
# --run-nvidia-xconfig Creates x11 config
tmpfile=$(mktemp)
curl -o $tmpfile -s https://us.download.nvidia.com/tesla/${NVIDIA_DRIVERS_VERSION}/NVIDIA-Linux-$(uname -i)-${NVIDIA_DRIVERS_VERSION}.run
chmod +x $tmpfile
sudo $tmpfile --silent --run-nvidia-xconfig

# Enable persistence mode
sudo nvidia-smi -pm 1

# Container toolkit for NVIDIA
distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.repo | sudo tee /etc/yum.repos.d/amzn2-nvidia.repo >/dev/null

sudo yum install -y \
    oci-add-hooks \
    nvidia-container-toolkit \
    nvidia-container-runtime-hook

# Reconfigure docker with the Nvidia drivers
sudo nvidia-ctk runtime configure --runtime=docker

# Runs a one-of script at every startup before the cloud-init is run
# It starts the nvidia-persistenced service, which prevents the GPU to go into sleep mode
# and the service also as a result keeps the /dev/nvidia* files persisted
#
# Cloud init will only enable GPU support if the /dev/nvidia* GPUs are visible
# https://github.com/aws/amazon-ecs-init/blob/master/ecs-init/gpu/nvidia_gpu_manager.go#L53
# https://download.nvidia.com/XFree86/Linux-x86_64/396.51/README/nvidia-persistenced.html
# https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#device-node-verification
tmpfile=$(mktemp)
cat >$tmpfile <<EOF
[Unit]
Before=cloud-init.service
Description=Enable NVIDIA persistence so the GPUs remain mounted.

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-persistenced
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# https://www.redhat.com/sysadmin/systemd-oneshot-service
sudo mv $tmpfile /etc/systemd/system/nv-persistence.service
sudo chmod 644 /etc/systemd/system/nv-persistence.service

# Reload new config as well as enable the persistenced service for running on evert instance start
sudo systemctl daemon-reload
sudo systemctl enable nv-persistence.service

mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config
