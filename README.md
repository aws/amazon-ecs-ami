# ECS-optimized AMI Build Recipes
> [!IMPORTANT]
> The ECS-optimized Amazon Linux 1 AMI (AL1) will reach its end-of-life (EOL) on September 15, 2025.
> The ECS-optimized Amazon Linux 2 AMI (AL2) will reach its EOL on June 30, 2026, mirroring the same EOL date of the upstream [Amazon Linux 2 Operating System](https://aws.amazon.com/amazon-linux-2/faqs).
> We encourage customers to upgrade their applications to use Amazon Linux 2023, which includes long term support through 2028.

This is a [packer](https://packer.io) recipe for creating an ECS-optimized AMI.
It will create a private AMI in whatever account you are running it in.

## Instructions

1. Setup AWS cli credentials.
2. Make the recipe that you want, REGION must be specified. Options are: al1, al2, al2arm, al2gpu, al2keplergpu, al2inf,
al2kernel5dot10, al2kernel5dot10arm, al2kernel5dot10gpu, al2kernel5dot10inf, al2023, al2023arm, al2023neu, al2023gpu.
```
REGION=us-west-2 make al2023
```

**NOTE**: `al2keplergpu` is a build recipe that this package supports to build ECS-Optimized GPU AMIs for instances with GPUs
with Kepler architecture (such as P2 type instances). ECS-Optimized GPU AMIs for this target are not officially built and published.

## Configuration

This recipe allows for configuration of your AMI. All configuration variables are defined and documented
in the file: `./variables.pkr.hcl`. This is also where some defaults are defined.

Variables can be set in `./release.auto.pkrvars.hcl` or `./overrides.auto.pkrvars.hcl`.

#### Overrides

If you would like to override any of the defaults provided here without committing any changes to git, you
can use the `overrides.auto.pkrvars.hcl` file, which is ignored by source control.

For example, if you want your AMI to have a smaller root block device, you can override the default value
of 30 GB like this:

```
export REGION=us-west-2
echo "block_device_size_gb = 8" > ./overrides.auto.pkrvars.hcl
make al2023
```

## Additional Packages

Any rpm package placed into the additional-packages/ directory will be uploaded to the instance and installed.

**NOTE**: All packages must end with extension `"$(uname -m).rpm"`, ie `.x86_64.rpm` or `.aarch64.rpm`.

## ECS Logs Collector

The ECS logs collector is a shell script that helps gather diagnostic information for troubleshooting ECS-related issues. This script is automatically installed on all ECS-optimized AMIs built with this recipe.

### Installation Details

The ECS logs collector is installed during the AMI build process with the following characteristics:

- **Installation Location**: `/opt/amazon/ecs/ecs-logs-collector.sh`
- **Version Tracking**: A version file is created at `/opt/amazon/ecs/ECS_LOG_COLLECTOR_VERSION` containing the commit hash
- **Permissions**: The script is executable and ready to use immediately after AMI launch
- **Source**: Downloaded directly from the official [aws/amazon-ecs-logs-collector](https://github.com/aws/amazon-ecs-logs-collector) GitHub repository

### Version Control

The installation script pins to a specific commit hash to ensure reproducible builds and version consistency. You can control which version is installed by setting the `ecs_logs_collector_commit_hash` variable:

```hcl
ecs_logs_collector_commit_hash = "03a216022fcb1304068a57feca412316192d858a"  # Default stable version
```

If not specified, the build will use the default commit hash defined in `variables.pkr.hcl`.

### Usage

To run the logs collector on an instance launched from the AMI:

```bash
# Run with default settings
sudo /opt/amazon/ecs/ecs-logs-collector.sh

# Run with custom options (see script help for available options)
sudo /opt/amazon/ecs/ecs-logs-collector.sh --help

# Check installed version
cat /opt/amazon/ecs/ECS_LOG_COLLECTOR_VERSION
```

The script will collect various logs and diagnostic information related to ECS and save them to a compressed archive for easy sharing with AWS support.

### Customizing the Version

To specify a different commit hash from the [aws/amazon-ecs-logs-collector](https://github.com/aws/amazon-ecs-logs-collector) repository:

1. Find the desired commit hash from the GitHub repository
2. Set the variable in your configuration file (e.g., `overrides.auto.pkrvars.hcl`):
   ```hcl
   ecs_logs_collector_commit_hash = "your-desired-commit-hash"
   ```
3. Build your AMI as usual

The build process will download and install the specific version of the logs collector corresponding to that commit hash, ensuring version consistency across your infrastructure.

### Finding and Updating the Commit Hash for ECS Logs Collector

To find the latest commit hash or a specific version of the ECS Logs Collector, you can use git commands with a minimal clone approach that only fetches commit history without downloading file contents:

```bash
# Create a minimal clone (no working directory, only git metadata)
git clone --bare --single-branch --branch master https://github.com/aws/amazon-ecs-logs-collector.git /tmp/ecs-logs-collector

# Navigate to the repository
cd /tmp/ecs-logs-collector

# Get the latest commit hash with subject that modified the ecs-logs-collector.sh script
git log -n 1 --pretty=format:"%H %s" -- ecs-logs-collector.sh

# Clean up the temporary directory
cd /
rm -rf /tmp/ecs-logs-collector
```

If the commit has the required changes then update the default commit hash for all builds, modify the `variables.pkr.hcl` file:

> Ensure we are in amazon-ecs-ami repository to avoid update failures

```bash
# Set the expected commit hash
LATEST_HASH=

# Update the default value in variables.pkr.hcl (handles any existing hash format)
sed -i "/ecs_logs_collector_commit_hash/,/default.*=/ s/default.*=.*/default     = \"$LATEST_HASH\"/" variables.pkr.hcl

# Verify the change
grep "ecs_logs_collector_commit_hash" -A 3 variables.pkr.hcl
```

## Cleanup

1. Deregister the AMI from EC2 Images via cli or console.
2. Delete the snapshot from EC2 EBS via cli or console.

## IAM Permissions

For details on the minimum IAM permissions required to build the AMI, please see the
packer docs: https://www.packer.io/docs/builders/amazon#iam-task-or-instance-role

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
