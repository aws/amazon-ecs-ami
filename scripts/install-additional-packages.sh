#!/usr/bin/env bash
set -ex

ARCH=$(uname -m)

# install any rpm packages from the additional-packages/ directory
if ls /tmp/additional-packages/*."${ARCH}".rpm; then
    echo "Found additional packages with architecture ${ARCH} to be installed"
    sudo yum localinstall -y /tmp/additional-packages/*."${ARCH}".rpm
else
    echo "No matching additional packages with architecture ${ARCH} found"
fi
if ls /tmp/additional-packages/*.noarch.rpm; then
    echo "Found additional packages with no specific architecture to be installed"
    sudo yum localinstall -y /tmp/additional-packages/*.noarch.rpm
else
    echo "No matching additional packages with no architecture found"
fi
