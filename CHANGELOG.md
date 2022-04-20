# Changelog

## 20220421

- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220406.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220406.1-arm64-ebs
- Enhancement: Update exec ssm agent version to 3.1.1260.0 and the sha256 checksums [#45](https://github.com/aws/amazon-ecs-ami/pull/45)
- Bugfix: Fixed AL_NAME for AL2022 scripts [#46](https://github.com/aws/amazon-ecs-ami/pull/46)
- Bugfix: Add nvidia-driver-latest-dkms package [#47](https://github.com/aws/amazon-ecs-ami/pull/47)

## 20220411

- ecs version: 1.61.0-1
- source al2022 ami: al2022-ami-minimal-2022.0.20220315.0-kernel-5.15-x86_64
- distribution al2022 release: 2022.0.20220315
- enhancement: AL2022 preview AMIs added [#43](https://github.com/aws/amazon-ecs-ami/pull/43)

## 20220328

- ecs version: 1.60.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220315.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220316.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220316.0-arm64-ebs

## 20220318

- ecs version: 1.60.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220315.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220316.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220316.0-arm64-ebs

## 20220304

- ecs version to 1.60.0-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220218.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220218.1-arm64-ebs
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220209.0-x86_64-ebs
- enhancement: set most_recent = true for source_ami_filter in order to avoid packer failures when duplicated AMIs exist [#34](https://github.com/aws/amazon-ecs-ami/pull/34)

## 20220209

- ecs version to 1.59.0-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220207.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220207.1-arm64-ebs
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220207.0-x86_64-ebs
- bug fix: inferentia AMI: disable broken neuron package upgrades [#27](https://github.com/aws/amazon-ecs-ami/pull/27)

## 20220121

- ecs version to 1.58.0-2
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20211223.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20211223.0-arm64-ebs
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20211222.0-x86_64-ebs
- bug fix: fix bug in inferentia/neuron AMI package installation [#25](https://github.com/aws/amazon-ecs-ami/pull/25)
- bug fix: nvidia package install change to fix issue when running a yum update [#21](https://github.com/aws/amazon-ecs-ami/pull/21)
- bug fix: delete /root/.aws/authorized_keys file on AMI build [#23](https://github.com/aws/amazon-ecs-ami/pull/23)
- enhancement: update the SSM Agent version to 3.1.804.0 [#24](https://github.com/aws/amazon-ecs-ami/pull/24)

## 20211209

- ecs version: 1.57.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20211201.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20211201.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20211201.0-arm64-ebs
- enhancement: added support for building with a user-specified ecs-init URL [#17](https://github.com/aws/amazon-ecs-ami/pull/17)
- bug fix: fix AL1 recipe block device mapping and devicemapper docker-storage setup [#18](https://github.com/aws/amazon-ecs-ami/pull/18)

## 20211120

- initial source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20211015.1-x86_64-ebs

## 20211115

- initial ecs version: 1.57.0-1
- initial source al2 ami: amzn2-ami-minimal-hvm-2.0.20211103.0-x86_64-ebs
- initial source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20211103.0-arm64-ebs
