#!/usr/bin/env bash
set -ex

sudo systemctl enable ecs
sudo systemctl enable amazon-ecs-volume-plugin
sudo systemctl enable amazon-ssm-agent
sudo systemctl enable rngd
