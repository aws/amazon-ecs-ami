#!/usr/bin/env bash
set -ex

# DCGM is not available in air-gapped (ADC/ISO) regions
if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region, skipping DCGM installation"
    exit 0
fi

# dcgm-init ships in the amazon-ecs-init RPM; skip until it's present. Checks the
# path directly since /usr/libexec is not on $PATH.
if [ ! -f /usr/libexec/dcgm-init ]; then
    echo "dcgm-init binary not found, skipping DCGM installation"
    exit 0
fi

### Determine DCGM version, as selected by check-update-security.sh
DCGM_FULL_VERSION=$(grep "^dcgm_version_al2023" /tmp/NVIDIA_DRIVER_VERSION | awk -F'"' '{print $2}')
if [[ -z $DCGM_FULL_VERSION ]]; then
    echo "ERROR: Could not read dcgm_version_al2023 from /tmp/NVIDIA_DRIVER_VERSION"
    exit 1
fi

# The package name embeds the major (datacenter-gpu-manager-4-core)
DCGM_MAJOR="${DCGM_FULL_VERSION%%.*}"
echo "Using DCGM version: ${DCGM_FULL_VERSION}"

### Install DCGM core package (provides nv-hostengine and libdcgm.so)
# Pinned to the exact version so the AMI matches what NVIDIA_DRIVER_VERSION
# records.
sudo dnf install -y "datacenter-gpu-manager-${DCGM_MAJOR}-core-${DCGM_FULL_VERSION}"

### Lock DCGM packages to prevent automatic updates
sudo dnf versionlock 'datacenter-gpu-manager*'

### Override nvidia-dcgm to use Unix domain socket instead of TCP
sudo mkdir -p /etc/systemd/system/nvidia-dcgm.service.d
sudo tee /etc/systemd/system/nvidia-dcgm.service.d/override.conf <<'EOF'
[Unit]
After=nvidia-persistenced.service
Wants=nvidia-persistenced.service

[Service]
ExecStartPre=/usr/bin/mkdir -p /var/log/ecs
ExecStart=
ExecStart=/usr/bin/nv-hostengine -n --service-account nvidia-dcgm --domain-socket /run/nvidia-dcgm/nv-hostengine -f /var/log/ecs/nv-hostengine.log
RuntimeDirectory=nvidia-dcgm
RuntimeDirectoryMode=0755
EOF
sudo systemctl daemon-reload

### Configure log rotation for DCGM logs
sudo tee /etc/logrotate.d/nv-hostengine <<'EOF'
/var/log/ecs/nv-hostengine.log {
    size 5M
    rotate 1
    missingok
    notifempty
    copytruncate
}
EOF

### Enable DCGM and dcgm-init services
sudo systemctl enable nvidia-dcgm
sudo systemctl enable dcgm-init
