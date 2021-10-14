#!/usr/bin/env bash
set -ex

sudo sed -i 's,^#releasever=,releasever=,' /etc/yum.conf
