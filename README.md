# ECS-optimized AMI Build Recipes
> [!IMPORTANT]
> The ECS-optimized Amazon Linux 1 AMI (AL1) has reached its end-of-life (EOL) on September 15, 2025.
> The ECS-optimized Amazon Linux 2 AMI (AL2) will reach its EOL on June 30, 2026, mirroring the same EOL date of the upstream [Amazon Linux 2 Operating System](https://aws.amazon.com/amazon-linux-2/faqs).
> We encourage customers to upgrade their applications to use Amazon Linux 2023, which includes long term support through 2028.

This is a [packer](https://packer.io) recipe for creating an ECS-optimized AMI.
It will create a private AMI in whatever account you are running it in.

## Instructions

1. Setup AWS cli credentials.
2. Make the recipe that you want, REGION must be specified. Options are: al2, al2arm, al2gpu, al2keplergpu, al2inf,
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
- **Version Tracking**: A version file is stored at `/opt/amazon/ecs/ECS_LOGS_COLLECTOR_VERSION` containing the git commit hash
- **Permissions**: The script is executable and ready to use immediately after AMI launch
- **Source**: Installed from the local script directory `./amazon-ecs-logs-collector/`

> For detailed usage information, visit: https://github.com/aws/amazon-ecs-logs-collector/?tab=readme-ov-file#usage

## Cleanup

1. Deregister the AMI from EC2 Images via cli or console.
2. Delete the snapshot from EC2 EBS via cli or console.

## IAM Permissions

For details on the minimum IAM permissions required to build the AMI, please see the
packer docs: https://www.packer.io/docs/builders/amazon#iam-task-or-instance-role

## Version-locked packages in AL2023 ECS GPU AMIs

Certain packages are critical for correct, performant behavior of GPU functionality in AL2023 ECS GPU AMIs. These include: - NVIDIA drivers (`nvidia*`) - Kernel modules (`kmod*`) - NVIDIA libraries (`libnvidia*`) - Kernel packages (`kernel*`)

> [!NOTE]
> This is not an exhaustive list. The complete list of locked packages are available with `dnf versionlock list`

These packages are version-locked to ensure stability and prevent unintentional changes that could disrupt GPU workloads. As a result, these packages should generally be modified within the bounds of a managed process that gracefully handles potential issues and maintains GPU functionality.

To prevent unintended modifications, the `dnf versionlock` plugin is used on these packages.

If you wish to modify a locked package, you can:
```
# unlock a single package
sudo dnf versionlock delete $PACKAGE_NAME 
# unlock all packages 
sudo dnf versionlock clear
```
> [!IMPORTANT]
> When updates to these packages are necessary, customers should consider using the latest AMI version that includes the required updates. If updating existing instances is required, a careful approach involving unlocking, updating, and re-locking packages should be employed, always ensuring GPU functionality is maintained throughout the process.

## Memory Overcommit Fix for g6f.large instance type

`g6f.large` instances require memory overcommit configuration to run ECS tasks with NVIDIA GPU support. Add this to your EC2 UserData or run directly on the instance:

```bash
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
```

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This project is licensed under the Apache-2.0 License.
