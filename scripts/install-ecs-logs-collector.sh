#!/usr/bin/env bash
set -exo pipefail

# ECS Logs Collector Installation Script
# Downloads and installs the AWS ECS logs collector from the official GitHub repository
# Pins to specific script version using commit hash

# Configuration
readonly INSTALLATION_DIR="/opt/amazon/ecs"
readonly VERSION_FILE="ECS_LOG_COLLECTOR_VERSION"
readonly SCRIPT_FILE="ecs-logs-collector.sh"

# Create directory for optional shell scripts
sudo mkdir -p ${INSTALLATION_DIR}

# Set appropriate file permissions
sudo chmod 755 ${INSTALLATION_DIR}

# Download ecs-logs-collector.sh
echo "Downloading ${SCRIPT_FILE} with commit hash: ${ECS_LOGS_COLLECTOR_COMMIT_HASH}"
sudo curl -fsSL -O --output-dir ${INSTALLATION_DIR} https://raw.githubusercontent.com/aws/amazon-ecs-logs-collector/${ECS_LOGS_COLLECTOR_COMMIT_HASH}/${SCRIPT_FILE}

# Add execute permissions
sudo chmod +x ${INSTALLATION_DIR}/${SCRIPT_FILE}

# Write commit hash to version file
echo ${ECS_LOGS_COLLECTOR_COMMIT_HASH} | sudo tee ${INSTALLATION_DIR}/${VERSION_FILE}

# Set appropriate file permissions
sudo chmod 644 ${INSTALLATION_DIR}/${VERSION_FILE}
