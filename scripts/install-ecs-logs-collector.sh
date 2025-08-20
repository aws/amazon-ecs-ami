#!/usr/bin/env bash
set -exo pipefail

# ECS Logs Collector Installation Script

# Configuration
readonly INSTALLATION_DIR="/opt/amazon/ecs"
readonly VERSION_FILE="ECS_LOG_COLLECTOR_VERSION"
readonly SCRIPT_FILE="ecs-logs-collector.sh"
readonly SOURCE_DIR="amazon-ecs-logs-collector"

# Create directory for optional shell scripts
sudo mkdir -p ${INSTALLATION_DIR}

# Set appropriate file permissions
sudo chmod 755 ${INSTALLATION_DIR}

# Move ecs-logs-collector.sh from /tmp
sudo mv /tmp/${SCRIPT_FILE} ${INSTALLATION_DIR}/${SCRIPT_FILE}

# Add execute permissions
sudo chmod +x ${INSTALLATION_DIR}/${SCRIPT_FILE}
