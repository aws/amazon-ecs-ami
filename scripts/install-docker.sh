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
