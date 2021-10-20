#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm
