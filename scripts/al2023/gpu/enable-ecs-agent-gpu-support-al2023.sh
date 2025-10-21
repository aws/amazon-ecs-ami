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
sudo mkdir -p /usr/share/docker-runtime-nvidia

# Create the nvidia runtime script
sudo tee /etc/docker-runtimes.d/nvidia <<'EOF'
#!/bin/sh
if [ ! -x /usr/sbin/runc ]; then
    runc_path=/usr/bin/docker-runc
else
    runc_path=/usr/sbin/runc
fi
exec /usr/bin/oci-add-hooks --hook-config-path /usr/share/docker-runtime-nvidia/hook-config.json --runtime-path "$runc_path" "$@"
EOF

# Create the NVIDIA container hook configuration
sudo tee /usr/share/docker-runtime-nvidia/hook-config.json <<'EOF'
{
  "hooks": {
    "prestart": [
      {
        "path": "/usr/bin/nvidia-container-runtime-hook",
        "args": ["/usr/bin/nvidia-container-runtime-hook", "prestart"]
      }
    ]
  }
}
EOF

# Set appropriate file permissions
sudo chmod 755 /etc/docker-runtimes.d/nvidia
sudo chmod 644 /usr/share/docker-runtime-nvidia/hook-config.json
