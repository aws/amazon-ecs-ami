#!/usr/bin/env bash
set -ex

### Install DCGM core package (provides nv-hostengine and libdcgm.so)
sudo dnf install -y "datacenter-gpu-manager-${DCGM_VERSION}-core"

### Lock DCGM packages to prevent updates that could break the libdcgm.so ABI
sudo dnf versionlock 'datacenter-gpu-manager*'

### Override nvidia-dcgm to use Unix domain socket instead of TCP
# dcgm-init connects via /run/nvidia-dcgm/nv-hostengine (matching ECS MI behavior)
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
