#!/usr/bin/env bash
set -ex

# Below command actually runs `sudo dnf clean all` for AL2023.
# See https://docs.aws.amazon.com/linux/al2023/ug/package-management.html for more details.
sudo yum clean all

function cleanup() {
    FILES=("$@")
    for FILE in "${FILES[@]}"; do
        if sudo test -f $FILE; then
            echo "Deleting $FILE"
            sudo shred -zuf $FILE
        fi
        if sudo test -f $FILE; then
            echo "Failed to delete '$FILE'. Failing."
            exit 1
        fi
    done
}

# Clean up for cloud-init files
CLOUD_INIT_FILES=(
    "/etc/locale.conf"
    "/var/log/cloud-init.log"
    "/var/log/cloud-init-output.log"
)
echo "Cleaning up cloud init files"
cleanup "${CLOUD_INIT_FILES[@]}"
if [[ $(sudo find /var/lib/cloud -type f | sudo wc -l) -gt 0 ]]; then
    echo "Deleting files within /var/lib/cloud/*"
    sudo find /var/lib/cloud -type f -exec shred -zuf {} \;
fi

if [[ $(sudo ls /var/lib/cloud | sudo wc -l) -gt 0 ]]; then
    echo "Deleting /var/lib/cloud/*"
    sudo rm -rf /var/lib/cloud/* || true
fi

# Clean up for temporary instance files
INSTANCE_FILES=(
    "/etc/.updated"
    "/etc/aliases.db"
    "/etc/hostname"
    "/var/lib/misc/postfix.aliasesdb-stamp"
    "/var/lib/postfix/master.lock"
    "/var/spool/postfix/pid/master.pid"
    "/var/.updated"
    "/var/cache/yum/x86_64/2/.gpgkeyschecked.yum"
)
echo "Cleaning up instance files"
cleanup "${INSTANCE_FILES[@]}"

# Clean up for ssh files
SSH_FILES=(
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
    "/etc/ssh/ssh_host_ecdsa_key"
    "/etc/ssh/ssh_host_ecdsa_key.pub"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/root/.ssh/authorized_keys"
)
echo "Cleaning up ssh files"
cleanup "${SSH_FILES[@]}"
# USERS=$(ls /home/)
USERS="ec2-user"
for user in $USERS; do
    echo Deleting /home/"$user"/.ssh/authorized_keys
    sudo find /home/"$user"/.ssh/authorized_keys -type f -exec shred -zuf {} \;
done
for user in $USERS; do
    if sudo test -f /home/"$user"/.ssh/authorized_keys; then
        echo Failed to delete /home/"$user"/.ssh/authorized_keys
        exit 1
    fi
done

INSTANCE_LOG_FILES=(
    "/var/log/audit/audit.log"
    "/var/log/boot.log"
    "/var/log/dmesg"
    "/var/log/messages"
    "/var/log/cron"
)
echo "Cleaning up instance log files"
cleanup "${INSTANCE_LOG_FILES[@]}"

echo "Cleaning TOE files"
if [[ $(sudo find {{workingDirectory}}/TOE_* -type f | sudo wc -l) -gt 0 ]]; then
    echo "Deleting files within {{workingDirectory}}/TOE_*"
    sudo find {{workingDirectory}}/TOE_* -type f -exec shred -zuf {} \;
fi
if [[ $(sudo find {{workingDirectory}}/TOE_* -type f | sudo wc -l) -gt 0 ]]; then
    echo "Failed to delete {{workingDirectory}}/TOE_*"
    exit 1
fi
if [[ $(sudo find {{workingDirectory}}/TOE_* -type d | sudo wc -l) -gt 0 ]]; then
    echo "Deleting {{workingDirectory}}/TOE_*"
    sudo rm -rf {{workingDirectory}}/TOE_*
fi
if [[ $(sudo find {{workingDirectory}}/TOE_* -type d | sudo wc -l) -gt 0 ]]; then
    echo "Failed to delete {{workingDirectory}}/TOE_*"
    exit 1
fi

echo "Cleaning up ssm log files"
if sudo test -d "/var/log/amazon/ssm"; then
    echo "Deleting /var/log/amazon/ssm/*"
    sudo rm -rf /var/log/amazon/ssm
fi
if sudo test -d "/var/log/amazon/ssm"; then
    echo "Failed to delete /var/log/amazon/ssm"
    exit 1
fi

if [[ $(sudo find /var/log/sa/sa* -type f | sudo wc -l) -gt 0 ]]; then
    echo "Deleting /var/log/sa/sa*"
    sudo shred -zuf /var/log/sa/sa*
fi
if [[ $(sudo find /var/log/sa/sa* -type f | sudo wc -l) -gt 0 ]]; then
    echo "Failed to delete /var/log/sa/sa*"
    exit 1
fi

if [[ $(sudo find /var/lib/dhclient/dhclient*.lease -type f | sudo wc -l) -gt 0 ]]; then
    echo "Deleting /var/lib/dhclient/dhclient*.lease"
    sudo shred -zuf /var/lib/dhclient/dhclient*.lease
fi
if [[ $(sudo find /var/lib/dhclient/dhclient*.lease -type f | sudo wc -l) -gt 0 ]]; then
    echo "Failed to delete /var/lib/dhclient/dhclient*.lease"
    exit 1
fi

if [[ $(sudo find /var/tmp -type f | sudo wc -l) -gt 0 ]]; then
    echo "Deleting files within /var/tmp/*"
    sudo find /var/tmp -type f -exec shred -zuf {} \;
fi
if [[ $(sudo find /var/tmp -type f | sudo wc -l) -gt 0 ]]; then
    echo "Failed to delete /var/tmp"
    exit 1
fi
if [[ $(sudo ls /var/tmp | sudo wc -l) -gt 0 ]]; then
    echo "Deleting /var/tmp/*"
    sudo rm -rf /var/tmp/*
fi

# Shredding is not guaranteed to work well on rolling logs

if sudo test -f "/var/lib/rsyslog/imjournal.state"; then
    echo "Deleting /var/lib/rsyslog/imjournal.state"
    sudo shred -zuf /var/lib/rsyslog/imjournal.state
    sudo rm -f /var/lib/rsyslog/imjournal.state
fi

if [[ $(sudo ls /var/log/journal/ | sudo wc -l) -gt 0 ]]; then
    echo "Deleting /var/log/journal/*"
    sudo find /var/log/journal/ -type f -exec shred -zuf {} \;
    sudo rm -rf /var/log/journal/*
fi

# delete a few items missed in https://docs.aws.amazon.com/imagebuilder/latest/userguide/security-best-practices.html
sudo rm -rf \
    /var/cache/dnf \
    /var/cache/yum \
    /tmp/* \
    /var/lib/dhcp/dhclient.* \
    /var/lib/dnf/history* \
    /var/lib/yum/history \
    /var/log/secure \
    /var/log/wtmp \
    /etc/ssh/ssh_host*

#sudo touch /etc/machine-id
sudo truncate -s 0 /etc/machine-id
