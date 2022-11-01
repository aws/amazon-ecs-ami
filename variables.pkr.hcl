packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  packages_al1    = "amazon-efs-utils ec2-net-utils acpid irqbalance numactl rng-tools docker-storage-setup"
  packages_al2    = "amazon-efs-utils ec2-net-utils acpid amazon-ssm-agent yum-plugin-upgrade-helper"
  packages_al2022 = "amazon-efs-utils amazon-ssm-agent amazon-ec2-net-utils acpid"
}

variable "ami_name_prefix_al2" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn2-ami-ecs"
}

variable "ami_name_prefix_al2022" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn2022-ami-ecs"
}

variable "ami_version" {
  type        = string
  description = "Outputted AMI version."
}

variable "region" {
  type        = string
  description = "Region to build the AMI in."
}

variable "block_device_size_gb" {
  type        = number
  default     = 30
  description = "Size of the root block device."
}

variable "ecs_agent_version" {
  type        = string
  description = "ECS agent version to build AMI with."
}

variable "ecs_init_rev" {
  type        = string
  description = "ecs-init package version rev"
}

variable "docker_version" {
  type        = string
  description = "Docker version to build AMI with."
}

variable "containerd_version" {
  type        = string
  description = "Containerd version to build AMI with."
}

variable "docker_version_al2022" {
  type        = string
  description = "Docker version to build AL2022 AMI with."
  default     = "20.10.17"
}

variable "containerd_version_al2022" {
  type        = string
  description = "Containerd version to build AL2022 AMI with."
  default     = "1.6.6"
}

variable "exec_ssm_version" {
  type        = string
  default     = "3.1.1732.0"
  description = "SSM binary version to build ECS exec support with."
}

variable "source_ami_al2" {
  type        = string
  description = "Amazon Linux 2 source AMI to build from."
}

variable "source_ami_al2arm" {
  type        = string
  description = "Amazon Linux 2 ARM source AMI to build from."
}

variable "source_ami_al2022" {
  type        = string
  description = "Amazon Linux 2022 source AMI to build from."
}

variable "source_ami_al2022arm" {
  type        = string
  description = "Amazon Linux 2022 ARM source AMI to build from."
}

variable "kernel_version_al2022" {
  type        = string
  description = "Amazon Linux 2022 kernel version."
}

variable "kernel_version_al2022arm" {
  type        = string
  description = "Amazon Linux 2022 ARM kernel version."
}

variable "ami_name_prefix_al1" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn-ami-2018.03."
}

variable "source_ami_al1" {
  type        = string
  description = "Amazon Linux 1 source AMI to build from."
}

variable "docker_version_al1" {
  type        = string
  description = "Docker version to build AL1 AMI with."
  default     = "20.10.13"
}

variable "ecs_version_al1" {
  type        = string
  description = "ECS version to build AL1 AMI with."
  default     = "1.51.0"
}

variable "air_gapped" {
  type        = string
  description = "If this build is for an air-gapped region, set to 'true'"
  default     = ""
}

variable "ecs_init_url_al2" {
  type        = string
  description = "Specify a particular ECS init URL for AL2 to install. If empty it will use the standard path."
  default     = ""
}

variable "ecs_init_url_al2022" {
  type        = string
  description = "Specify a particular ECS init URL for AL2022 to install. If empty it will use the standard path."
  default     = ""
}

variable "ecs_init_local_override" {
  type        = string
  description = "Specify a local init rpm under /additional-packages to be used for building AL2 and AL2022 AMIs. If empty it will use ecs_init_url if specified, otherwise the standard path"
  default     = ""
}
