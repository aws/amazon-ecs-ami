# Changelog

## Source AMI release notes
- [Amazon Linux 2023 release notes](https://docs.aws.amazon.com/linux/al2023/release-notes/relnotes.html)
- [Amazon Linux 2 release notes](https://docs.aws.amazon.com/AL2/latest/relnotes/relnotes-al2.html)
- [Amazon Linux AMI 2018.03 Release Notes](https://aws.amazon.com/amazon-linux-ami/2018.03-release-notes/)

## 20240712
- ecs version: 1.85.1
- al2 ami version: 20240712
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240709.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240709.1-arm64-ebs
- source al2 kernel 5.10 ami:  amzn2-ami-minimal-hvm-2.0.20240709.1-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240709.1-arm64-ebs
- al2023 ami version: 20240712
- source al2023 ami: al2023-ami-minimal-2023.5.20240708.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.5.20240708.0-kernel-6.1-arm64
- distribution al2023 release: 2023.5.20240708
- enhancement: Update ECS Agent version to 1.85.1 [#272](https://github.com/aws/amazon-ecs-ami/pull/272)

## 20240709
- al2 ami version: 20240709
- al2023 ami version: 20240709
- enhancement: Update ECS Agent version to 1.85.0 [#268](https://github.com/aws/amazon-ecs-ami/pull/268)
- enhancement: Update AL2 Docker version to 25.0.3 [#267](https://github.com/aws/amazon-ecs-ami/pull/267) 

## 20240702
- al2023 ami version: 20240702
- source al2023 ami: al2023-ami-minimal-2023.5.20240701.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.5.20240701.0-kernel-6.1-arm64
- distribution al2023 release: 2023.5.20240701
- bug fix: Install pinned docker, containerd, and runc versions in Air-gapped regions instead of installing the latest available [#263](https://github.com/aws/amazon-ecs-ami/pull/263)

## 20240625
- al2 ami version: 20240625
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240620.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240620.0-arm64-ebs
- source al2 kernel 5.10 ami:  amzn2-ami-minimal-hvm-2.0.20240620.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240620.0-arm64-ebs
- al2023 ami version: 20240625
- source al2023 ami: al2023-ami-minimal-2023.5.20240624.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.5.20240624.0-kernel-6.1-arm64
- distribution al2023 release: 2023.5.20240624
- enhancement: Update ECS Agent version to 1.84.0 [#261](https://github.com/aws/amazon-ecs-ami/pull/261)

## 20240613
- al2 ami version: 20240613
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240610.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240610.1-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240610.1-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240610.1-arm64-ebs

## 20240611
- al2 ami version: 20240611
- enhancement: Disable security updates at launch for ECS-optimized AL2 AMIs [#254](https://github.com/aws/amazon-ecs-ami/pull/254)

## 20240610
- al2 ami version: 20240610
- al2023 ami version: 20240610
- source al2023 ami: al2023-ami-minimal-2023.4.20240611.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240611.0-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240611

## 20240604
- ecs version: 1.83.0
- al2 ami version: 20240604
- al2023 ami version: 20240604
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240529.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240529.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240529.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240529.0-arm64-ebs
- enhancement: Add include_deprecated=true to all AMI recipes. [#249](https://github.com/aws/amazon-ecs-ami/pull/249)

## 20240528
- al2 ami version: 20240528
- al2023 ami version: 20240528
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240521.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240521.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240521.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240521.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.4.20240528.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240528.0-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240528

## 20240515
- ecs version: 1.82.4
- al2 ami version: 20240515
- al2023 ami version: 20240515
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240503.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240503.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240503.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240503.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.4.20240513.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240513.0-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240513

## 20240430
- al2023 ami version: 20240430
- source al2023 ami: al2023-ami-minimal-2023.4.20240429.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240429.0-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240429

## 20240424
- ecs version: 1.82.3
- al2 ami version: 20240424
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240412.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240412.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240412.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240412.0-arm64-ebs
- al2023 ami version: 20240424
- source al2023 ami: al2023-ami-minimal-2023.4.20240416.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240416.0-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240416

## 20240409
- ecs version: 1.82.2
- al2 ami version: 20240409
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240329.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240329.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240329.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240329.0-arm64-ebs
- al2023 ami version: 20240409
- source al2023 ami: al2023-ami-minimal-2023.4.20240401.1-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240401.1-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240401

## 20240328
- ecs version: 1.82.1
- al2 ami version: 20240328
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240318.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240318.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240318.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240318.0-arm64-ebs
- al2023 ami version: 20240328
- docker version al2023: 25.0.3
- source al2023 ami: al2023-ami-minimal-2023.4.20240319.1-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.4.20240319.1-kernel-6.1-arm64
- distribution al2023 release: 2023.4.20240319
- enhancement: Update AL2023 Docker version to 25.0.3 [#228](https://github.com/aws/amazon-ecs-ami/pull/228)
- bug fix: Setup ECS config directory if not present [#230](https://github.com/aws/amazon-ecs-ami/pull/230)

## 20240319
- al1 ami version: 20240319
- al2 ami version: 20240319
- al2023 ami version: 20240319
- source al2023 ami: al2023-ami-minimal-2023.3.20240312.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240312.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240312
- enhancement: Update SSM Agent version to 3.2.2303.0 for ECS exec [#223](https://github.com/aws/amazon-ecs-ami/pull/223)

## 20240312
- al2 ami version: 20240312
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240306.2-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240306.2-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240306.2-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240306.2-arm64-ebs
- al2023 ami version: 20240312
- source al2023 ami: al2023-ami-minimal-2023.3.20240304.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240304.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240304
- enhancement: Add AL2 GPU/INF kernel 5.10 AMIs to release notes [#221](https://github.com/aws/amazon-ecs-ami/pull/221)

## 20240305
- al1 ami version: 20240305
- al2 ami version: 20240305
- al2023 ami version: 20240305
- ecs version: 1.82.0-1
- feature: Support AL2 kernel 5.10 GPU and INF [#214](https://github.com/aws/amazon-ecs-ami/pull/214)
- enhancement: Update exec ssm version to 3.2.2222.0 [#217](https://github.com/aws/amazon-ecs-ami/pull/217)

## 20240227
- al2 ami version: 20240227
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240223.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240223.0-arm64-ebs
- source al2 kernel 5.10 ami:  amzn2-ami-minimal-hvm-2.0.20240223.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240223.0-arm64-ebs

## 20240221
- ecs version: 1.81.1-1
- contaienrd version: 1.7.11
- containerd version al2023: 1.7.11
- al2 ami version: 20240221
- al2023 ami version: 20240221
- enhancement: Update generate release notes script to factor in decoupled ami_version across ami families [#205](https://github.com/aws/amazon-ecs-ami/pull/205)

## 20240212
- al1 ami version: 20240201
- al2 ami version: 20240207
- al2023 ami version: 20240207
- source al2023 ami: al2023-ami-minimal-2023.3.20240205.2-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240205.2-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240205
- enhancement: ECS-Optimized AMIs release enhancements [#197](https://github.com/aws/amazon-ecs-ami/pull/197), [#199](https://github.com/aws/amazon-ecs-ami/pull/199), [#200](https://github.com/aws/amazon-ecs-ami/pull/200), [#201](https://github.com/aws/amazon-ecs-ami/pull/201), [#202](https://github.com/aws/amazon-ecs-ami/pull/202)
- enhancement: change amzn2-extras.repo file owner to root [#198](https://github.com/aws/amazon-ecs-ami/pull/198)

## 20240201
- ecs version: 1.81.0-1
- containerd version: 1.7.2
- containerd version al2023: 1.7.2
- runc version: 1.1.11
- runc version al2023: 1.1.11
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240131.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240131.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240131.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240131.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.3.20240131.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240131.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240131

## 20240131
- ecs version: 1.80.0-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240124.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240124.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240124.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240124.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.3.20240122.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240122.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240122
- enhancement: Bump packer amazon plugin to source deprecated amis for al1 build.[#192](https://github.com/aws/amazon-ecs-ami/pull/192)
- enhancement: Add runc to versioned parameters for installation.[#193](https://github.com/aws/amazon-ecs-ami/pull/193)
- bug fix: Fix al2gpu AMI package installs and updates when running in isolated subnets. [#191](https://github.com/aws/amazon-ecs-ami/pull/191)

## 20240109
- ecs version: 1.80.0-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20240109.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20240109.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20240109.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20240109.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.3.20240108.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20240108.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20240108

## 20231219
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20231218.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20231218.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20231218.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20231218.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20231218.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.3.20231218.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.3.20231218.0-kernel-6.1-arm64
- distribution al2023 release: 2023.3.20231218

## 20231213
- ecs version: 1.79.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20231206.1-x86_64-ebs
- source al2 gpu ami: amzn2-ami-minimal-hvm-2.0.20231206.0-x86_64-ebs

## 20231211
- ecs version: 1.79.2-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20231206.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20231206.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20231206.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20231206.0-arm64-ebs
- Enhancement: Add open source nvidia kernel module .tar file and install script. [#163](https://github.com/aws/amazon-ecs-ami/pull/163)

## 20231204
- ecs version: 1.79.1-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20231116.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20231116.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20231116.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20231116.0-arm64-ebs
- Enhancement: skip shredding files since we're deleting the entire directory [#168](https://github.com/aws/amazon-ecs-ami/pull/168)
- Enhancement: Make EBS CSI driver version overridable [#172](https://github.com/aws/amazon-ecs-ami/pull/172)

## 20231114
- ecs version: 1.79.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20231106.0-x86_64-ebs
- source al2023 ami: al2023-ami-minimal-2023.2.20231113.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.2.20231113.0-kernel-6.1-arm64
- distribution al2023 release: 2023.2.20231113

## 20231103
- ecs version: 1.79.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20231024.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20231101.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20231101.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20231101.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20231101.0-arm64-ebs
- source al2 gpu ami: amzn2-ami-minimal-hvm-2.0.20230926.0-x86_64-ebs
- source al2023 ami: al2023-ami-minimal-2023.2.20231030.1-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.2.20231030.1-kernel-6.1-arm64
- distribution al2023 release: 2023.2.20231030
- Feature: Add support for EBS tasks to the ECS-Optimized AMI [#154](https://github.com/aws/amazon-ecs-ami/pull/154)
- Enhancement: Update docker version to 20.10.25 in the script [#157](https://github.com/aws/amazon-ecs-ami/pull/157)
- Enhancement: Temporarily override GPU base AMI [#161](https://github.com/aws/amazon-ecs-ami/pull/161)

## 20231024
- ecs version: 1.78.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20231002.0-x86_64-ebs
- docker version: 20.10.25
- docker version al2023: 20.10.25
- enhancement: Install aws-neuronx-tools in AL2INF and AL2023NEU [#149](https://github.com/aws/amazon-ecs-ami/pull/149)
- enhancement: Update SSM Agent version to 3.2.1630.0 for ECS exec [#150](https://github.com/aws/amazon-ecs-ami/pull/150)
- bug fix: Fix a typo in the enable inf support script [#152](https://github.com/aws/amazon-ecs-ami/pull/152)
- bug fix: add al2keplergpu build recipe to build gpu amis for kepler arch [#153](https://github.com/aws/amazon-ecs-ami/pull/153)

## 20230929
- ecs version: 1.77.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230918.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230926.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230926.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230926.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230926.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.2.20230920.1-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.2.20230920.1-kernel-6.1-arm64
- distribution al2023 release: 2023.2.20230920
- Enhancement: Enable NVIDIA Persistence Daemon by default [#147](https://github.com/aws/amazon-ecs-ami/pull/147)
- Enhancement: Use gpg check to validate exec ssm agent [#146](https://github.com/aws/amazon-ecs-ami/pull/146)

## 20230912
- ecs version: 1.76.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230905.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230906.0-x86_64-eb
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230906.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230906.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230906.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.1.20230912.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230912.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230912

## 20230906
- ecs version: 1.75.3-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230821.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230822.0-x86_64-eb
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230822.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230822.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230822.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.1.20230825.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230825.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230825
- enhancement: Update execute-command-agent to 3.2.1478.0. [#141](https://github.com/aws/amazon-ecs-ami/pull/141)

## 20230809
- ecs version: 1.75.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230807.0-x86_64-ebs
- source al2023 ami: al2023-ami-minimal-2023.1.20230809.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230809.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230809

## 20230731
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230724.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230727.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230727.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230727.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230727.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.1.20230725.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230725.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230725

## 20230720
- ecs version: 1.74.1-1
- source al2023 ami: al2023-ami-minimal-2023.1.20230719.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230719.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230719

## 20230705
- ecs version: 1.73.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230628.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230628.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230628.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230628.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230628.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.1.20230705.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.1.20230705.0-kernel-6.1-arm64
- distribution al2023 release: 2023.1.20230705

## 20230627
- ecs version: 1.73.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230607.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230612.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230612.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230612.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230612.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.0.20230614.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.0.20230614.0-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230614
- Enhancement: Add a script to generate release notes [#132](https://github.com/aws/amazon-ecs-ami/pull/132)

## 20230606
- ecs version: 1.72.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230601.0-x86_64-ebs
- source ami al2: amzn2-ami-minimal-hvm-2.0.20230530.0-x86_64-ebs
- source ami al2arm: amzn2-ami-minimal-hvm-2.0.20230530.0-arm64-ebs
- source ami al2kernel5dot10: amzn2-ami-minimal-hvm-2.0.20230530.0-x86_64-ebs
- source ami al2kernel5dot10arm: amzn2-ami-minimal-hvm-2.0.20230530.0-arm64-ebs
- source ami al2023: al2023-ami-minimal-2023.0.20230607.0-kernel-6.1-x86_64
- source ami al2023arm: al2023-ami-minimal-2023.0.20230607.0-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230607
- docker version: 20.10.23
- docker version al2023: 20.10.23
- containerd version: 1.6.19
- containerd version al2023: 1.6.19
- Enhancement: moved AL2023 docker and containerd version declaration to generate-release-var.sh

## 20230530

- ecs version: 1.71.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230515.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230515.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230515.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230515.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230515.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.0.20230517.1-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.0.20230517.1-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230517

## 20230509

- ecs version: 1.71.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230501.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230504.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230504.1-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230504.1-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230504.1-arm64-ebs
- Fix: Change docker version and containerd version in release config generation script [#126](https://github.com/aws/amazon-ecs-ami/pull/126)

## 20230428
- ecs version: [1.71.0-1](https://github.com/aws/amazon-ecs-agent/releases/tag/v1.71.0)
- al2 docker version: 20.10.22
- al2 containerd version: 1.6.19
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230419.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230418.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230418.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230418.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230418.0-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.0.20230503.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.0.20230503.0-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230503
- Enhancement: Update docker version to 20.10.22 and containerd version to 1.6.19 for AL2
- Enhancement: Support Service Connect on ECS-optimized Amazon Linux 2023 AMI

## 20230420

- ecs version: 1.70.2-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230404.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230404.1-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230404.1-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230404.1-arm64-ebs
- source al2023 ami: al2023-ami-minimal-2023.0.20230419.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.0.20230419.0-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230419

## 20230406

- ecs version: 1.70.1-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230404.0-x86_64-ebs
- source al2023 ami: al2023-ami-minimal-2023.0.20230329.0-kernel-6.1-x86_64
- source al2023 arm ami: al2023-ami-minimal-2023.0.20230329.0-kernel-6.1-arm64
- distribution al2023 release: 2023.0.20230329
- Fix: default AL2023 neuron builds to inf1 instance types [#116](https://github.com/aws/amazon-ecs-ami/pull/116)

## 20230321

- ecs version: 1.70.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230322.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230320.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230320.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230320.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230320.0-arm64-ebs
- Feature: Add AL2023 AMI

## 20230314

- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230306.1-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230307.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230307.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230307.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230307.0-arm64-ebs

## 20230301

- ecs version: 1.69.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230221.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230221.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230221.0-arm64-ebs
- source al2 kernel 5.10 ami: amzn2-ami-minimal-hvm-2.0.20230221.0-x86_64-ebs
- source al2 kernel 5.10 arm ami: amzn2-ami-minimal-hvm-2.0.20230221.0-arm64-ebs
- bug fix: Don't use spot instances to build AMIs [#106](https://github.com/aws/amazon-ecs-ami/pull/106)
## 20230214

- ecs version: 1.68.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20230207.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20230119.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20230119.1-arm64-ebs
- source al2022 ami: al2022-ami-minimal-2022.0.20230118.3-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20230118.3-kernel-5.15-arm64
- Enhancement: Use `spot_instance_types` for building AMIs [#104](https://github.com/aws/amazon-ecs-ami/pull/104)

## 20230127

- ecs version: 1.68.1-1
- distribution al2022 release: 2022.0.20230118

## 20230109

- ecs version: 1.68.0-1

## 20221230

- ecs version: 1.67.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20221209.1-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20221210.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20221210.1-arm64-ebs 
- source al2022 ami: al2022-ami-minimal-2022.0.20221207.4-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20221207.4-kernel-5.15-arm64

## 20221213

- ecs version: 1.67.2-1

## 20221207

- ecs version: 1.67.1-1
- source al2022 ami: al2022-ami-minimal-2022.0.20221103.1-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20221103.1-kernel-5.15-arm64
- distribution al2022 release: 2022.0.20221207
- feature: Add AL2 kernel 5.10 recipes for x86_64 and arm64 [#97](https://github.com/aws/amazon-ecs-ami/pull/97)

## 20221118

- source al2 ami: amzn2-ami-minimal-hvm-2.0.20221103.3-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20221103.3-arm64-ebs

## 20221115

- ecs version: 1.66.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20221018.0-x86_64-ebs
- enhancement: Add back oci-add-hooks to neuron recipe (AL2INF only) [#90](https://github.com/aws/amazon-ecs-ami/pull/90)
- bug fix: Reverting the change to disable userland proxy [#91](https://github.com/aws/amazon-ecs-ami/pull/91)

## 20221102

- ecs version: 1.65.1-1
- source al2022 ami: al2022-ami-minimal-2022.0.20221101.0-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20221101.0-kernel-5.15-arm64
- distribution al2022 release: 2022.0.20221101 

## 20221025

- ecs version: 1.65.0-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20221004.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20221004.0-arm64-ebs
- source al2022 ami: al2022-ami-minimal-2022.0.20221019.4-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20221019.4-kernel-5.15-arm64
- distribution al2022 release: 2022.0.20221019
- enhancement: Updating docker verison to 20.10.17 and containerd version to 1.6.6 for AL2
- enhancement: AL2022 AMI name - drop root volume type, add kernel version [#81](https://github.com/aws/amazon-ecs-ami/pull/81)

## 20221010

- ecs version: 1.64.0-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220907.3-x86_64-ebs
- source al2022 ami: al2022-ami-minimal-2022.0.20220928.0-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20220928.0-kernel-5.15-arm64
- distribution al2022 release: 2022.0.20220928
- enhancement: Update to Exec SSM Agent version 3.1.1732.0 [#80](https://github.com/aws/amazon-ecs-ami/pull/80)

## 20220921

- ecs version: 1.63.1-1
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220912.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220912.1-arm64-ebs
- feature: AL2022 Neuron Support [#76](https://github.com/aws/amazon-ecs-ami/pull/76)

## 20220831

- Enhancement: Neuron/Inf AMIs, update Neuron build script to use Neuron V2 [#70](https://github.com/aws/amazon-ecs-ami/pull/70)
- Enhancement: AL2022 defaults to gp3 volumes [#72](https://github.com/aws/amazon-ecs-ami/pull/72)
- Enhancement: AL2022 install ssm agent from official AL repo [#72](https://github.com/aws/amazon-ecs-ami/pull/72)
- source al2022 x86 ami: al2022-ami-minimal-2022.0.20220824.0-kernel-5.15-x86_64
- source al2022 arm ami: al2022-ami-minimal-2022.0.20220824.0-kernel-5.15-arm64
- al2022 distribution release: 2022.0.20220831

## 20220822

- ecs version: 1.62.2-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220802.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220805.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220805.0-arm64-ebs

## 20220810

- distribution al2022 release: 2022.0.20220810
- al2022 docker/containerd version update

## 20220805

- ecs version 1.62.1-1

## 20220630

## 20220627

- ecs version: 1.61.3-1
- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220609.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220606.1-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220606.1-arm64-ebs
- source al2022 ami: al2022-ami-minimal-2022.0.20220531.0-kernel-5.15-x86_64
- distribution al2022 release: 2022.0.20220531

## 20220607

- ecs version: 1.61.2-1

## 20220520

- source al2022 ami: al2022-ami-minimal-2022.0.20220504.1-kernel-5.15-x86_64
- source al2022arm ami: al2022-ami-minimal-2022.0.20220504.1-kernel-5.15-arm64
- distribution al2022 release: 2022.0.20220518
- Enhancement: Updating docker to 20.10.13 and containerd to 1.4.13 for AL2022 [#55](https://github.com/aws/amazon-ecs-ami/pull/55)

## 20220509

- source al1 ami: amzn-ami-minimal-hvm-2018.03.0.20220419.0-x86_64-ebs
- source al2 ami: amzn2-ami-minimal-hvm-2.0.20220426.0-x86_64-ebs
- source al2 arm ami: amzn2-ami-minimal-hvm-2.0.20220426.0-arm64-ebs
- source al2022 ami: al2022-ami-minimal-2022.0.20220419.0-kernel-5.15-x86_64
- distribution al2022 release: 2022.0.20220504
- Enhancement: Cleanup /var/log/messages [#49](https://github.com/aws/amazon-ecs-ami/pull/49)
- Enhancement: Updating docker to 20.10.13 and containerd to 1.4.13 for all AMIs except AL2022 [#51](https://github.com/aws/amazon-ecs-ami/pull/51)
- Enhancement: Updating docker and containerd versions in generate-release-vars script [#52](https://github.com/aws/amazon-ecs-ami/pull/52)
- Bugfix: fixing variable name `ami_name_x86` -> `ami_name_al2_x86` in generate-release-vars.sh [#53](https://github.com/aws/amazon-ecs-ami/pull/53)

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
