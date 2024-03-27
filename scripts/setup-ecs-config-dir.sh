#!/usr/bin/env bash
set -ex

sudo mkdir -p "/etc/ecs"

if [ ! -f "/etc/ecs/ecs.config" ]; then
    sudo touch /etc/ecs/ecs.config
fi

if [ ! -f "/etc/ecs/ecs.config.json" ]; then
    sudo touch /etc/ecs/ecs.config.json
fi
