#!/usr/bin/env bash
set -ex

if [ -n "$AIR_GAPPED" ]; then
    echo "Air-gapped region, assuming ecs-init and dependencies will be in additional-packages/ directory"
    exit 0
fi

WORK_DIR="$(mktemp -d)"
trap "rm -rf ${WORK_DIR}" EXIT

if [ -z "$INIT_LOCAL_OVERRIDE" ]; then # no local overrides, retrieve from S3
	if [ -z "$ECS_INIT_URL" ]; then # S3 URL not specified, use standard path
	    ARCH=$(uname -m)
	    host_suffix=""
	    if grep -q "^cn-" <<<"$REGION"; then
	        host_suffix=".cn"
	    fi
	    ECS_INIT_URL="https://s3.$REGION.amazonaws.com${host_suffix}/amazon-ecs-agent-$REGION/ecs-init-$AGENT_VERSION-$INIT_REV.$AL_NAME.$ARCH.rpm"
	fi
	curl -fLSs -o "$WORK_DIR/ecs-init.rpm" "$ECS_INIT_URL"
	curl -fLSs -o "$WORK_DIR/ecs-init.rpm.asc" "${ECS_INIT_URL}.asc"
else
	mv "/tmp/additional-packages/$ECS_INIT_LOCAL_OVERRIDE" "$WORK_DIR/ecs-init.rpm"
	mv "/tmp/additional-packages/$ECS_INIT_LOCAL_OVERRIDE.asc" "$WORK_DIR/ecs-init.rpm.asc"
fi

gpg --import "/tmp/$PGP_KEY_FILE"
gpg --verify "$WORK_DIR/ecs-init.rpm.asc" "$WORK_DIR/ecs-init.rpm"

sudo yum install -y "$WORK_DIR/ecs-init.rpm"
