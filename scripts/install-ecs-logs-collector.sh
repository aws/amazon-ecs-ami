#!/usr/bin/env bash
set -exo pipefail

# ECS Logs Collector Installation Script

# Configuration
readonly INSTALLATION_DIR="/opt/amazon/ecs"
readonly SCRIPT_FILE="ecs-logs-collector.sh"

# Create directory for optional shell scripts
sudo mkdir -p ${INSTALLATION_DIR}

# Set appropriate file permissions
sudo chmod 755 ${INSTALLATION_DIR}

# Move install ECS Logs Collector to /opt/amazon/ecs
sudo mv /tmp/amazon-ecs-logs-collector/* ${INSTALLATION_DIR}/

# Add execute permissions
sudo chmod +x ${INSTALLATION_DIR}/${SCRIPT_FILE}
