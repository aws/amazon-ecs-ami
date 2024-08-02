#!/usr/bin/env bash
set -ex

if command -v amazon-linux-extras; then
    # enable docker "extras" repo when available
    sudo amazon-linux-extras enable docker
fi

sudo yum install -y "docker-$DOCKER_VERSION" "containerd-$CONTAINERD_VERSION" "runc-$RUNC_VERSION"
