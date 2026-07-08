#!/usr/bin/env bash
set -ex

# DCGM is not available in air-gapped (ADC/ISO) regions
if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region, skipping DCGM installation"
    exit 0
fi

# The dcgm-init binary (and its systemd unit) ships in the amazon-ecs-init RPM,
# which is installed earlier in the build. Older RPMs don't include it yet, so
# skip DCGM setup entirely until the binary is present (mirrors AIR_GAPPED).
# Note: the binary lives in /usr/libexec, which is not on $PATH, so this checks
# the install path directly rather than using `command -v`/`which`.
if [ ! -f /usr/libexec/dcgm-init ]; then
    echo "dcgm-init binary not found, skipping DCGM installation"
    exit 0
fi

### Install DCGM core package (provides nv-hostengine and libdcgm.so)
sudo dnf install -y "datacenter-gpu-manager-${DCGM_VERSION}-core"

### Lock DCGM packages to prevent updates that could break the libdcgm.so ABI
sudo dnf versionlock 'datacenter-gpu-manager*'

### Override nvidia-dcgm to use Unix domain socket instead of TCP
sudo mkdir -p /etc/systemd/system/nvidia-dcgm.service.d
sudo tee /etc/systemd/system/nvidia-dcgm.service.d/override.conf <<'EOF'
[Unit]
After=nvidia-persistenced.service
Wants=nvidia-persistenced.service

[Service]
ExecStart=
ExecStart=/usr/bin/nv-hostengine -n --service-account nvidia-dcgm --domain-socket /run/nvidia-dcgm/nv-hostengine
RuntimeDirectory=nvidia-dcgm
RuntimeDirectoryMode=0755
EOF
sudo systemctl daemon-reload

### Enable DCGM and dcgm-init services
sudo systemctl enable nvidia-dcgm
sudo systemctl enable dcgm-init
