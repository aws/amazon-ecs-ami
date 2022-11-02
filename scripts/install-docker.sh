#!/usr/bin/env bash
set -ex

if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region, assuming docker and dependencies will be in additional-packages/ directory"
    exit 0
fi

if command -v amazon-linux-extras; then
    # enable docker "extras" repo when available
    sudo amazon-linux-extras enable docker
fi

sudo yum install -y "docker-$DOCKER_VERSION" "containerd-$CONTAINERD_VERSION"

WORK_DIR="$(mktemp -d)"
trap "rm -rf ${WORK_DIR}" EXIT

cat >"$WORK_DIR/docker-daemon-config.json" <<EOF
{
    "userland-proxy": false
}
EOF

sudo mkdir -p /etc/docker && sudo mv "$WORK_DIR/docker-daemon-config.json" /etc/docker/daemon.json
