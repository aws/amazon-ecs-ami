#!/usr/bin/env bash
set -ex

# Temporarily pin to version 1.29.12.1 as latest available version 1.29.12.2 in Amazon Linux repos has a known issue.
sudo yum install -y ecs-service-connect-agent-v1.29.12.1-*
