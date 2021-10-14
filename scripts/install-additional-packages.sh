#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
for rpm in $(ls /tmp/additional-packages/*."${ARCH}".rpm); do
    sudo yum install -y "$rpm"
done
