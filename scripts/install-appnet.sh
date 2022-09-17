#!/usr/bin/env bash
set -ex

BINARY_PATH="/var/lib/ecs/deps/serviceconnect"
sudo mkdir -p "${BINARY_PATH}"
sudo mv /tmp/appnet_agent.interface-v1.tar "${BINARY_PATH}"/appnet_agent.interface-v1.tar
