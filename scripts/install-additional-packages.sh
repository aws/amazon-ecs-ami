#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
if [[ $(sudo find /tmp/additional-packages/*."${ARCH}".rpm -type f | sudo wc -l) -gt 0 ]]; then
    echo "Found additional packages with architecture ${ARCH} to be installed"
    sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm
fi
if [[ $(sudo find /tmp/additional-packages/*.noarch.rpm -type f | sudo wc -l) -gt 0 ]]; then
    echo "Found additional packages with no specific architecture to be installed"
    sudo yum localinstall -y /tmp/additional-packages/*.noarch.rpm
fi
