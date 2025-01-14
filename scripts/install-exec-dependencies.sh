#!/usr/bin/env bash
set -ex

# Attempts to download a file using curl and exits the script gracefully if the download fails.
# Usage: download_or_exit_gracefully <url> <output_file>
download_or_exit_gracefully() {
    curl -fLSs "$1" -o "$2" || {
        echo "Error: Failed to download $2"
        exit 0
    }
}

# Returns AWS DNS suffix from $REGION_DNS_SUFFIX if set, errors if no dns suffix set for air-gapped regions.
# Defaults to amazonaws.com[.cn]
get_dns_suffix() {
    # If $REGION_DNS_SUFFIX is assigned and non-empty, use that
    if [ -n "$REGION_DNS_SUFFIX" ]; then
        echo "Using configured DNS suffix: $REGION_DNS_SUFFIX"
        return
    fi

    if [ -n "$AIR_GAPPED" ]; then
        echo "Air-gapped region, need to set DNS suffix explicitly"
        exit 1
    fi

    local host_suffix=""
    if grep -q "^cn-" <<<"$REGION"; then
        host_suffix=".cn"
    fi
    echo "amazonaws.com${host_suffix}"
}

cleanup() {
    if [ -d "/tmp/ssm-binaries" ]; then
        rm -rf /tmp/ssm-binaries
    fi
}

trap cleanup EXIT

DNS_SUFFIX=$(get_dns_suffix)

BINARY_PATH="/var/lib/ecs/deps/execute-command/bin/${EXEC_SSM_VERSION}"
CERTS_PATH="/var/lib/ecs/deps/execute-command/certs"
ARCHITECTURE="$(uname -m)"

# Download ssm agent static binaries in BINARY_PATH
mkdir -p /tmp/ssm-binaries && cd /tmp/ssm-binaries

# Import ssm agent public key
gpg --import /tmp/amazon-ssm-agent.gpg

case $ARCHITECTURE in
'x86_64')
    download_or_exit_gracefully "https://amazon-ssm-${REGION}.s3.${REGION}.${DNS_SUFFIX}/${EXEC_SSM_VERSION}/linux_amd64/amazon-ssm-agent-binaries.tar.gz" "amazon-ssm-agent.tar.gz"
    download_or_exit_gracefully "https://amazon-ssm-${REGION}.s3.${REGION}.${DNS_SUFFIX}/${EXEC_SSM_VERSION}/linux_amd64/amazon-ssm-agent-binaries.tar.gz.sig" "amazon-ssm-agent.tar.gz.sig"
    ;;
'aarch64')
    download_or_exit_gracefully "https://amazon-ssm-${REGION}.s3.${REGION}.${DNS_SUFFIX}/${EXEC_SSM_VERSION}/linux_arm64/amazon-ssm-agent-binaries.tar.gz" "amazon-ssm-agent.tar.gz"
    download_or_exit_gracefully "https://amazon-ssm-${REGION}.s3.${REGION}.${DNS_SUFFIX}/${EXEC_SSM_VERSION}/linux_arm64/amazon-ssm-agent-binaries.tar.gz.sig" "amazon-ssm-agent.tar.gz.sig"
    ;;
esac
gpg --verify amazon-ssm-agent.tar.gz.sig amazon-ssm-agent.tar.gz

sudo tar -xvf amazon-ssm-agent.tar.gz
sudo mkdir -p "${BINARY_PATH}"
sudo cp amazon-ssm-agent "${BINARY_PATH}"/amazon-ssm-agent
sudo cp ssm-agent-worker "${BINARY_PATH}"/ssm-agent-worker
sudo cp ssm-session-worker "${BINARY_PATH}"/ssm-session-worker
rm -rf /tmp/ssm-binaries

# Copy certs with 400 permission in CERTS_PATH
sudo mkdir -p ${CERTS_PATH} && cd ${CERTS_PATH}
sudo cp /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem tls-ca-bundle.pem
sudo chmod 400 tls-ca-bundle.pem
