#!/usr/bin/env bash
set -ex

# ECS-optimized AMIs are provisioned with two disks:
# 1) Root volume at /dev/sda (GP3, 8GB, delete on terminate)
# 2) Extra EBS volume at /dev/xvdcz just for Docker (GP3, 22GB, delete on terminate)
#
# We use docker-storage-setup to configure this additional device properly.
# By default docker-storage-setup will configure 40% of the device, and will
# then grow the available space over time up to the maximum in the pool
# (volume group).  We can tweak the initial space higher if necessary, but
# cannot set DATA_SIZE=100%FREE, as some space must be reserved for the
# metadata and root of the pool.
#
# VG=docker because that's what the volume group is for.
cat >>/tmp/docker-storage-setup <<EOF
DEVS=/dev/xvdcz
VG=docker
DATA_SIZE=99%FREE
AUTO_EXTEND_POOL=yes
LV_ERROR_WHEN_FULL=yes
EXTRA_DOCKER_STORAGE_OPTIONS="--storage-opt dm.fs=ext4 --storage-opt dm.use_deferred_deletion=true"
EOF
sudo mv /tmp/docker-storage-setup /etc/sysconfig/docker-storage-setup
