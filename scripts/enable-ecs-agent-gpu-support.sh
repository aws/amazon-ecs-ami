#!/usr/bin/env bash
set -ex

# Makes sure that a compatible version of gcc is used for compiling NVIDIA driver.
set_compatible_gcc_version_for_nvidia_compile() {
    # Currently a compatible version of gcc is assumed to be used by default, unless the AMI recipe uses kernel 5.10.
    if [[ $AMI_TYPE == *"kernel5dot10gpu" ]]; then
        # Explicitly use gcc10 since gcc version for compiling the NVIDIA driver must match gcc version with which the
        # Linux kernel was compiled.
        sudo sed -i "s/'make' -j2 module/& CC=\/usr\/bin\/gcc10-cc/" /usr/src/${MODULE_NAME}-${MODULE_VERSION}/dkms.conf
    fi
}

if [[ $AMI_TYPE != "al2"*"gpu" ]]; then
    exit 0
fi

# set up amzn2-nvidia repo
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

DKMS=/usr/sbin/dkms
DKMS_ARCHIVE_DIR=/var/lib/dkms-archive

# the amzn2-nvidia repo is temporary and only used for installing the system-release-nvidia package
sudo mv $tmpfile /etc/yum.repos.d/amzn2-nvidia-tmp.repo

# only install open driver for post-kepler gpus, exclude airgapped regions
if [[ $AMI_TYPE != "al2keplergpu" && -z ${AIR_GAPPED} ]]; then
    sudo yum install -y yum-plugin-versionlock yum-utils
    sudo amazon-linux-extras install epel -y
    sudo yum install -y "kernel-devel-uname-r == $(uname -r)"

    # pull nvidia version from what's available in amzn2-nvidia
    # trim after `:` until `-` to get the major.minor.patch version
    NVIDIA_VERSION=$(yum list available | grep nvidia-kmod-common | awk '{print $2}' | sed -e 's/.*://' -e 's/-.*//')

    # disable amzn2 in favor of rh repo
    sudo yum-config-manager --disable amzn2-nvidia
    sudo yum-config-manager --add-repo=https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo
    sudo yum-config-manager --enable cuda-rhel7.repo

    # install open dkms from rh repo
    sudo yum install -y nvidia-kmod-common-${NVIDIA_VERSION}

    # build nvidia-open kmod tar
    MODULE_NAME="nvidia-open"
    MODULE_VERSION=$(${DKMS} status -m ${MODULE_NAME} | awk '{print $2}' | tr -d ',:')
    set_compatible_gcc_version_for_nvidia_compile
    sudo ${DKMS} build -m "${MODULE_NAME}" -v "${MODULE_VERSION}"
    sudo ${DKMS} mktarball -m "${MODULE_NAME}" -v "${MODULE_VERSION}"
    sudo mkdir -p "${DKMS_ARCHIVE_DIR}/${MODULE_NAME}/"
    sudo cp /var/lib/dkms/${MODULE_NAME}/${MODULE_VERSION}/tarball/*.tar.gz "${DKMS_ARCHIVE_DIR}/${MODULE_NAME}/"

    # re-enable amzn2 and clean up
    sudo yum remove -y kmod-nvidia-open-dkms
    sudo yum-config-manager --disable cuda-rhel7.repo
    sudo rm /etc/yum.repos.d/cuda-rhel7.repo
    # epel was used to install dkms, now delete as it points to public http endpoints which
    # can cause problems for customers using isolated subnets.
    sudo yum-config-manager --disable epel
    sudo rm /etc/yum.repos.d/epel.repo
    sudo rm /etc/yum.repos.d/epel-testing.repo
    sudo amazon-linux-extras disable epel
    sudo rm -rf /var/cache/yum
    sudo yum-config-manager --enable amzn2-nvidia

    # copy install-nvidia-open-kmod.sh to host
    sudo mkdir -p /var/lib/ecs/scripts

    tmpfile=$(mktemp)
    cat >$tmpfile <<"EOF"
#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o xtrace
DKMS=/usr/sbin/dkms
DKMS_ARCHIVE_DIR=/var/lib/dkms-archive
KERNEL_VERSION="$(uname -r)"
MODULE_VERSION=$(${DKMS} status -m nvidia | awk '{print $2}' | tr -d ',:')
${DKMS} uninstall -m nvidia -v ${MODULE_VERSION}
NVIDIA_TO_REMOVE="nvidia/${MODULE_VERSION}"
${DKMS} remove ${NVIDIA_TO_REMOVE} --all
echo "found nvidia kernel module: ${MODULE_VERSION}"
MODULE_ARCHIVE="${DKMS_ARCHIVE_DIR}/nvidia-open/nvidia-open-${MODULE_VERSION}-kernel${KERNEL_VERSION}-x86_64.dkms.tar.gz"
echo "loading from ${MODULE_ARCHIVE}"
${DKMS} ldtarball ${MODULE_ARCHIVE}
${DKMS} install -m nvidia -v ${MODULE_VERSION}
sudo systemctl daemon-reload
${DKMS} status -m nvidia
EOF

    sudo mv $tmpfile /var/lib/ecs/scripts/install-nvidia-open-kmod.sh
    sudo chmod +x /var/lib/ecs/scripts/install-nvidia-open-kmod.sh
fi

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
        libnvidia-container1 \
        libnvidia-container-tools \
        nvidia-container-toolkit-base \
        nvidia-container-toolkit

    sudo yum install -y cuda-drivers \
        cuda
fi

if [[ $AMI_TYPE == *"kernel5dot10gpu" ]]; then
    # rebuild module/update drivers using compatible gcc version (gcc10)
    MODULE_NAME="nvidia"
    MODULE_VERSION=$(${DKMS} status -m ${MODULE_NAME} | awk '{print $2}' | tr -d ',:')
    set_compatible_gcc_version_for_nvidia_compile
    sudo ${DKMS} install -m "${MODULE_NAME}" -v "${MODULE_VERSION}"
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
