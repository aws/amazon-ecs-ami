# ECS-optimized AMI Build Recipes

**PREVIEW** This project is currently in preview and is not tested or ready for production.

This is a [packer](https://packer.io) recipe for creating an ECS-optimized AMI.
It will create a private AMI in whatever account you are running it in.

## Instructions

1. Setup AWS cli credentials.
2. Make the recipe that you want, REGION must be specified. Options are: al1, al2, al2arm, al2gpu, al2inf.
```
REGION=us-west-2 make al2
```

## Configuration

This recipe allows for configuration of your AMI. All configuration variables are defined and documented
in the file: `./variables.pkr.hcl`. This is also where some defaults are defined.

Variables can be set in `./release.auto.pkrvars.hcl` or `./overrides.auto.pkrvars.hcl`.

#### Overrides

If you would like to override any of the defaults provided here without commiting any changes to git, you
can use the `overrides.auto.pkrvars.hcl` file, which is ignored by source control.

For example, if you want your AMI to have a smaller root block device, you can override the default value
of 30 GB like this:

```
export REGION=us-west-2
echo "block_device_size_gb = 8" > ./overrides.auto.pkrvars.hcl
make al2
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
