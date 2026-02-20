#!/usr/bin/env bash
set -ex

# Temporarily pin to version 1.34.4.2 as latest available version has a known issue.
sudo yum install -y ecs-service-connect-agent-v1.34.4.2-*
