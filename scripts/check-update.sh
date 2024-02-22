#!/usr/bin/env bash
set -exo pipefail

usage() {
    echo "Usage:"
    echo "  $0 AMI_TYPE"
    echo "Example:"
    echo "  $0 al2"
    echo "AMI_TYPE Must be one of: al1, al2, al2023"
}

error() {
    local msg="$1"
    echo "ERROR: $msg"
    usage
    exit 1
}

readonly ami_type="$1"
if [ -z "$ami_type" ]; then
    error "AMI_TYPE must be provided"
fi

cp release-$ami_type.auto.pkrvars.hcl release-$ami_type.old.hcl
./generate-release-vars.sh $ami_type
diff_val=$(diff <(grep -v ami_version release-$ami_type.old.hcl) <(grep -v ami_version release-$ami_type.auto.pkrvars.hcl))
# If no difference in dependencies, check for security update
if [ -z "$diff_val" ]; then
    # al2023 version already generates a diff in dependency file if it has security updates, so no check necessary if al2023
    if [ "$ami_type" != "al2023" ]; then
        Update=$(./scripts/check-update-security.sh $ami_type)
        if [ "$Update" != "true" ] && [ "$ami_type" != "al1" ]; then
            Update=$(./scripts/check-update-security.sh "$ami_type"_arm)
        fi
    fi
else
    Update="true"
fi

rm "release-$ami_type.old.hcl"

if [ "$Update" = "true" ]; then
    echo "Update exists for $ami_type"
    git add release-$ami_type.auto.pkrvars.hcl
else
    echo "Update does not exist for $ami_type"
fi
