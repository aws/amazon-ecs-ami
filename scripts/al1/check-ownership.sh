#!/usr/bin/env bash
set -ex

check_ownership() {
    path=$1
    expected_user=$2
    expected_group=$3

    actual_user=$(stat -c '%U' "${path}")
    if [ "${actual_user}" != "${expected_user}" ]; then
        echo "ERROR: Ownership for ${path}: expected user is ${expected_user}, actual user found was ${actual_user}"
        exit 1
    fi

    actual_group=$(stat -c '%G' "${path}")
    if [ "${actual_group}" != "${expected_group}" ]; then
        echo "ERROR: Ownership for ${path}: expected group is ${expected_group}, actual group found was ${actual_group}"
        exit 1
    fi
}

check_ownership /var/spool/mail root mail
