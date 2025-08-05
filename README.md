# ECS-optimized AMI Build Recipes
> [!IMPORTANT]
> The ECS-optimized Amazon Linux 1 AMI (AL1) will reach its end-of-life (EOL) on September 15, 2025.
> The ECS-optimized Amazon Linux 2 AMI (AL2) will reach its EOL on June 30, 2026, mirroring the same EOL date of the upstream [Amazon Linux 2 Operating System](https://aws.amazon.com/amazon-linux-2/faqs).
> We encourage customers to upgrade their applications to use Amazon Linux 2023, which includes long term support through 2028.

This is a [packer](https://packer.io) recipe for creating an ECS-optimized AMI.
It will create a private AMI in whatever account you are running it in.

## Instructions

1. Setup AWS cli credentials.
2. Make the recipe that you want. REGION must be specified. INSTANCE_TYPE can be specified if desired. Options are: 
al1, al2, al2arm, al2gpu, al2keplergpu, al2inf, al2kernel5dot10, al2kernel5dot10arm, al2kernel5dot10gpu, 
al2kernel5dot10inf, al2023, al2023arm, al2023neu, al2023gpu.

Example without INSTANCE_TYPE specified:
```
REGION=us-west-2 make al2023
```

Example with INSTANCE_TYPE specified:
```
REGION=ap-east-2 INSTANCE_TYPE=c6i.large make al2023
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
