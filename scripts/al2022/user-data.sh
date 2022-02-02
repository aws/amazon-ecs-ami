#!/bin/bash

# https://github.com/hashicorp/packer/issues/10074#issuecomment-886137013
sudo sed -i -r -e \
    's/^(PubkeyAcceptedKeyTypes )(.*)/\1ssh-rsa,\2/' \
    /etc/crypto-policies/back-ends/opensshserver.config

sudo systemctl restart sshd
