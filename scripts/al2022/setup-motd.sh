#!/usr/bin/env bash
set -ex

# AL2022 uses pam-motd, for docs see:
# http://www.linux-pam.org/Linux-PAM-html/sag-pam_motd.html

# disable the Amazon Linux motd banner (found at /usr/lib/motd.d/30-banner):
sudo ln -s /dev/null /etc/motd.d/30-banner

# add the ECS motd banner
echo -e "
   __|  __|  __|
   _|  (   \__ \   Amazon Linux 2022 (ECS Optimized)
 ____|\___|____/   Preview

For documentation, visit http://aws.amazon.com/documentation/ecs" >/tmp/31-banner
sudo mv /tmp/31-banner /etc/motd.d/31-banner
