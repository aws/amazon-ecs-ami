#!/usr/bin/env bash
set -ex

if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region does not yet support service connect"
    exit 0
fi

ARCH=$(uname -m)
WORK_DIR="$(mktemp -d)"
trap "rm -rf ${WORK_DIR}" EXIT

s3_region="us-east-1"
host_suffix=""
appnet_s3_bucket="yinyic-test-appnet-rpm" # REPLACE ME

if grep -q "^cn-" <<<"$REGION"; then
    s3_region="cn-north-1"
    host_suffix=".cn"
elif grep -q "^gov-" <<<"$REGION"; then
    s3_region="us-gov-east-1"
fi

s3_url="https://s3.${s3_region}.amazonaws.com${host_suffix}/${appnet_s3_bucket}-${s3_region}/ecs-service-connect-agent-v1.25.4.0-1.amzn2023.${ARCH}.rpm"

curl -fLSs -o "$WORK_DIR/ecs-service-connect-agent-v1.25.4.0-1.amzn2023.${ARCH}.rpm" "$s3_url"

sudo yum localinstall -y ${WORK_DIR}/ecs-service-connect-agent-v1.25.4.0-1.amzn2023.${ARCH}.rpm

