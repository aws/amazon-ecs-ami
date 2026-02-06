#!/usr/bin/env bash
set -ex

# Only proceed for AL2023 GPU AMIs
if [[ $AMI_TYPE != "al2023"*"gpu" ]]; then
    exit 0
fi

### Configure ECS GPU Support
mkdir -p /tmp/ecs
echo 'ECS_ENABLE_GPU_SUPPORT=true' >/tmp/ecs/ecs.config
sudo mv /tmp/ecs/ecs.config /var/lib/ecs/ecs.config

### Configure GPU Container Runtime
# Create required directories
sudo mkdir -p /etc/docker-runtimes.d

# Create the NVIDIA runtime script
sudo tee /etc/docker-runtimes.d/nvidia <<'EOF'
#!/bin/sh
exec /usr/bin/nvidia-container-runtime "$@"
EOF

# Set appropriate file permissions
sudo chmod 755 /etc/docker-runtimes.d/nvidia

### Configure nvidia-container-runtime for debug logging
# Use nvidia-ctk config to set log-level to debug and debug log path to /var/log/ecs/
sudo nvidia-ctk config --in-place --set nvidia-container-runtime.log-level=debug
sudo nvidia-ctk config --in-place --set nvidia-container-runtime.debug=/var/log/ecs/nvidia-container-runtime.log

### Configure log rotation for nvidia-container-runtime logs
sudo tee /etc/logrotate.d/nvidia-container-runtime <<'EOF'
/var/log/ecs/nvidia-container-runtime.log {
    size 5M
    rotate 1
    missingok
    notifempty
    copytruncate
}
EOF
