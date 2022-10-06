#!/usr/bin/env bash
set -ex

if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region, exec feature is not supported"
    exit 0
fi

BINARY_PATH="/var/lib/ecs/deps/execute-command/bin/${EXEC_SSM_VERSION}"
CERTS_PATH="/var/lib/ecs/deps/execute-command/certs"
ARCHITECTURE="$(uname -m)"

host_suffix=""
if grep -q "^cn-" <<<"$REGION"; then
    host_suffix=".cn"
fi

# Download ssm agent static binaries in BINARY_PATH
mkdir -p /tmp/ssm-binaries && cd /tmp/ssm-binaries
case $ARCHITECTURE in
'x86_64')
    curl -fLSs "https://amazon-ssm-${REGION}.s3.${REGION}.amazonaws.com${host_suffix}/${EXEC_SSM_VERSION}/linux_amd64/amazon-ssm-agent-binaries.tar.gz" -o amazon-ssm-agent.tar.gz
    echo "0100e5f6299274150d9252eb56ace6f3ff797ee2e9c17be1d6b9b8035b75315c ./amazon-ssm-agent.tar.gz" >./amazon-ssm-agent.tar.gz.sha256
    sha256sum -c ./amazon-ssm-agent.tar.gz.sha256
    ;;
'aarch64')
    curl -fLSs "https://amazon-ssm-${REGION}.s3.${REGION}.amazonaws.com${host_suffix}/${EXEC_SSM_VERSION}/linux_arm64/amazon-ssm-agent-binaries.tar.gz" -o amazon-ssm-agent.tar.gz
    echo "2f345a98ed25a9ffeb12355533b242110a502c929dd3abd61c2936000d22f230 ./amazon-ssm-agent.tar.gz" >./amazon-ssm-agent.tar.gz.sha256
    sha256sum -c ./amazon-ssm-agent.tar.gz.sha256
    ;;
esac

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
