#!/usr/bin/env bash
set -ex

if [[ $AMI_TYPE != "al2"*"inf" && $AMI_TYPE != "al2023neu" ]]; then
    exit 0
fi

# docs about installing neuron docker environment on inferentia instances:
# https://awsdocs-neuron.readthedocs-hosted.com/en/latest/neuron-deploy/tutorials/tutorial-docker-env-setup.html
# https://awsdocs-neuron.readthedocs-hosted.com/en/latest/neuron-intro/mxnet-setup/mxnet-install.html#install-neuron-mxnet

# Copy the neuron repo
cat >/tmp/neuron.repo <<EOF
[neuron]
name=neuron
baseurl=https://yum.repos.neuron.amazonaws.com/
priority=12
gpgcheck=0
gpgkey=https://yum.repos.neuron.amazonaws.com/GPG-PUB-KEY-AMAZON-AWS-NEURON.PUB
enabled=1
keepcache=0
EOF

sudo mv /tmp/neuron.repo /etc/yum.repos.d/neuron.repo

# Install inf1 downgrade support for al2023neu (files copied to /tmp by packer)
if [[ $AMI_TYPE == "al2023neu" ]]; then
    sudo dnf install -y 'dnf-command(versionlock)'

    # Install downgrade script and systemd service for inf1 compatibility
    sudo mkdir -p /var/lib/ecs/scripts/
    sudo cp /tmp/neuron-inf1-downgrade.sh /var/lib/ecs/scripts/
    sudo chmod +x /var/lib/ecs/scripts/neuron-inf1-downgrade.sh
    sudo cp /tmp/neuron-inf1-downgrade.service /etc/systemd/system/
    sudo systemctl enable neuron-inf1-downgrade.service
fi

# Install OS headers
sudo yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r) -y

# Install Neuron Driver
if [[ $AMI_TYPE == "al2inf" ]]; then
    # Pin the aws-neuronx-dkms package version to 2.17.17.0 only for al2inf, since the newest versions of the Neuron SDK are no longer supporting linux kernel 4.14
    sudo yum install -y aws-neuronx-dkms-2.17.17.0
elif [[ $AMI_TYPE == "al2kernel5dot10inf" ]]; then
    # Pin the aws-neuron-dkms package version to 2.21* for legacy al2kernel5dot10inf
    # Refer: https://awsdocs-neuron.readthedocs-hosted.com/en/latest/general/announcements/neuron2.x/announce-eos-neuron-driver-support-inf1.html
    sudo yum install -y aws-neuronx-dkms-2.21.*
else
    # For al2023neu and future AMI types: prepare inf1 downgrade packages and install latest
    sudo mkdir -p /opt/ecs/neuron/inf1-rpms
    sudo chmod 755 /opt/ecs/neuron/inf1-rpms
    cd /opt/ecs/neuron/inf1-rpms
    sudo dnf download aws-neuronx-dkms-2.21.*
    cd -
    sudo yum install -y aws-neuronx-dkms
fi
sudo yum install -y aws-neuronx-oci-hook-2.*

# Install oci-add-hooks
sudo yum install -y oci-add-hooks

# Install Neuron Tools
if [[ $AMI_TYPE == "al2inf" || $AMI_TYPE == "al2kernel5dot10inf" ]]; then
    # Pin the aws-neuronx-tools package version to 2.25.145.0, newer versions have incompatiblity with glibc 2.26.0 installed on AL2
    sudo yum install -y aws-neuronx-tools-2.25.145.0
else
    sudo yum install -y aws-neuronx-tools
fi

# disable neuron package upgrades by deleting the yum repo
sudo rm /etc/yum.repos.d/neuron.repo

NEURON_RUNTIME=/etc/docker-runtimes.d/neuron
# Add env variable to identify if inf is supported on this ami
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_INF_SUPPORT=true' >>/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config

# Copy neuron runtime to docker runtime to be accessed as one of the runtimes supported.
if [ ! -f $NEURON_RUNTIME ]; then
    sudo cp /opt/aws/neuron/bin/oci_neuron_hook_wrapper.sh $NEURON_RUNTIME
    sudo chmod +x $NEURON_RUNTIME
fi
