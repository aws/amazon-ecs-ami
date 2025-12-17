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

# Install OS headers
sudo yum install kernel-devel-$(uname -r) kernel-headers-$(uname -r) -y

# Install Neuron Driver
if [[ $AMI_TYPE == "al2inf" ]]; then
    # Pin the aws-neuronx-dkms package version to 2.17.17.0 only for al2inf, since the newest versions of the Neuron SDK are no longer supporting linux kernel 4.14
    sudo yum install -y aws-neuronx-dkms-2.17.17.0
else
    # Pin the aws-neuron-dkms package version to 2.21* for al2kernel5dot10inf and al2023neu
    # Refer: https://awsdocs-neuron.readthedocs-hosted.com/en/latest/general/announcements/neuron2.x/announce-eos-neuron-driver-support-inf1.html
    sudo yum install -y aws-neuronx-dkms-2.21.*
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
