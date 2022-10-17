#!/usr/bin/env bash
set -ex

BINARY_PATH="/var/lib/ecs/deps/serviceconnect"
sudo mkdir -p "${BINARY_PATH}"
sudo mv /tmp/ecs-service-connect-agent.interface-v1.tar "${BINARY_PATH}"/ecs-service-connect-agent.interface-v1.tar
