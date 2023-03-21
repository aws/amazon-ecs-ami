#!/usr/bin/env bash
set -ex

# AL2023 uses pam-motd, for docs see:
# http://www.linux-pam.org/Linux-PAM-html/sag-pam_motd.html

# disable the Amazon Linux motd banner (found at /usr/lib/motd.d/30-banner):
sudo ln -s /dev/null /etc/motd.d/30-banner

# add the ECS motd banner
echo -e "
   ,     #_
   ~\_  ####_
  ~~  \_#####\
  ~~     \###|
  ~~       \#/ ___   Amazon Linux 2023 (ECS Optimized)
   ~~       V~' '->
    ~~~         /
      ~~._.   _/
         _/ _/
       _/m/'

For documentation, visit http://aws.amazon.com/documentation/ecs" >/tmp/31-banner
sudo mv /tmp/31-banner /etc/motd.d/31-banner
