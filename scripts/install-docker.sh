#!/usr/bin/env bash
set -ex

sudo amazon-linux-extras enable docker
sudo yum install -y "docker-$DOCKER_VERSION" "containerd-$CONTAINERD_VERSION"
