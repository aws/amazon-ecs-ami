# shellcheck shell=bash

# get_default_aws_host_suffix returns the default AWS host suffix for any given AWS region.
get_default_aws_host_suffix() {
    local region="$1"
    local host_suffix="amazonaws.com"
    if grep -q "^cn-" <<<"$region"; then
        host_suffix="${host_suffix}.cn"
    fi

    if grep -q "^eusc-" <<<"$region"; then
        host_suffix="amazonaws.eu"
    fi

    echo "${host_suffix}"
}
