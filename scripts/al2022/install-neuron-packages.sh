#!/usr/bin/env bash
set -ex

# install packages required by neuron but not in al2022 repos yet - dkms yum-plugin-dkms-build-requires oci-add-hooks
# download them and put them under additional-packages/al2022
if [[ $AMI_TYPE == "al2022neu" ]]; then
    sudo yum localinstall -y /tmp/additional-packages/al2022/*.rpm
fi
