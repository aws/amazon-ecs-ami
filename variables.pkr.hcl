packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  packages_al1    = "amazon-efs-utils ec2-net-utils acpid irqbalance numactl rng-tools docker-storage-setup"
  packages_al2    = "amazon-efs-utils ec2-net-utils acpid amazon-ssm-agent yum-plugin-upgrade-helper iproute-tc"
  packages_al2023 = "amazon-efs-utils amazon-ssm-agent amazon-ec2-net-utils acpid iproute-tc"
}

variable "ami_name_prefix_al1" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn-ami-2018.03."
}

variable "ami_name_prefix_al2" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn2-ami-ecs"
}

variable "ami_name_prefix_al2023" {
  type        = string
  description = "Outputted AMI name prefix."
  default     = "unofficial-amzn2023-ami-ecs"
}

variable "ami_version_al1" {
  type        = string
  description = "Outputted AMI version."
}

variable "ami_version_al2" {
  type        = string
  description = "Outputted AMI version."
}

variable "ami_version_al2023" {
  type        = string
  description = "Outputted AMI version."
}

variable "region" {
  type        = string
  description = "Region to build the AMI in."
}

variable "block_device_size_gb" {
  type        = number
  description = "Size of the root block device."
  default     = 30
}

variable "ecs_agent_version" {
  type        = string
  description = "ECS agent version to build AMI with."
  default     = "1.89.1"
}

variable "ecs_init_rev" {
  type        = string
  description = "ecs-init package version rev"
  default     = "1"
}

variable "docker_version" {
  type        = string
  description = "Docker version to build AMI with."
  default     = "25.0.6"
}

variable "containerd_version" {
  type        = string
  description = "Containerd version to build AMI with."
  default     = "1.7.25"
}

variable "runc_version" {
  type        = string
  description = "Runc version to build AMI with."
  default     = "1.1.14"
}

variable "docker_version_al2023" {
  type        = string
  description = "Docker version to build AL2023 AMI with."
  default     = "25.0.6"
}

variable "containerd_version_al2023" {
  type        = string
  description = "Containerd version to build AL2023 AMI with."
  default     = "1.7.25"
}

variable "runc_version_al2023" {
  type        = string
  description = "Runc version to build AL2023 AMI with."
  default     = "1.1.14"
}

variable "exec_ssm_version" {
  type        = string
  description = "SSM binary version to build ECS exec support with."
  default     = "3.3.859.0"
}

variable "source_ami_al2" {
  type        = string
  description = "Amazon Linux 2 source AMI to build from."
}

variable "source_ami_al2arm" {
  type        = string
  description = "Amazon Linux 2 ARM source AMI to build from."
}

variable "source_ami_al2kernel5dot10" {
  type        = string
  description = "Amazon Linux 2 Kernel 5.10 source AMI to build from."
}

variable "source_ami_al2kernel5dot10arm" {
  type        = string
  description = "Amazon Linux 2 Kernel 5.10 ARM source AMI to build from."
}

variable "source_ami_al2023" {
  type        = string
  description = "Amazon Linux 2023 source AMI to build from."
}

variable "source_ami_al2023arm" {
  type        = string
  description = "Amazon Linux 2023 ARM source AMI to build from."
}

variable "distribution_release_al2023" {
  type        = string
  description = "Amazon Linux 2023 distribution release."
}

variable "kernel_version_al2023" {
  type        = string
  description = "Amazon Linux 2023 kernel version."
}

variable "kernel_version_al2023arm" {
  type        = string
  description = "Amazon Linux 2023 ARM kernel version."
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

variable "ecs_init_url_al2023" {
  type        = string
  description = "Specify a particular ECS init URL for AL2023 to install. If empty it will use the standard path."
  default     = ""
}

variable "ecs_init_local_override" {
  type        = string
  description = "Specify a local init rpm under /additional-packages to be used for building AL2 and AL2023 AMIs. If empty it will use ecs_init_url if specified, otherwise the standard path"
  default     = ""
}

variable "general_purpose_instance_types" {
  type        = list(string)
  description = "List of available in-region instance types for general-purpose platform"
  default     = ["c5.large"]
}

variable "gpu_instance_types" {
  type        = list(string)
  description = "List of available in-region instance types for GPU platform"
  default     = ["c5.4xlarge"]
}

variable "arm_instance_types" {
  type        = list(string)
  description = "List of available in-region instance types for ARM platform"
  default     = ["m6g.xlarge"]
}

variable "inf_instance_types" {
  type        = list(string)
  description = "List of available in-region instance types for INF platform"
  default     = ["inf1.xlarge"]
}

variable "neu_instance_types" {
  type        = list(string)
  description = "List of available in-region instance types for NEU platform"
  default     = ["inf1.xlarge"]
}

variable "managed_daemon_base_url" {
  type        = string
  description = "Base URL (minus file name) to download managed daemons from."
  default     = ""
}

variable "ebs_csi_driver_version" {
  type        = string
  description = "EBS CSI driver version to build AMI with."
  default     = ""
}

variable "ami_ou_arns" {
  type        = list(string)
  description = "A list of Amazon Resource Names (ARN) of AWS Organizations organizational units (OU) that have access to launch the resulting AMI(s)."
  default     = []
}

variable "ami_org_arns" {
  type        = list(string)
  description = "A list of Amazon Resource Names (ARN) of AWS Organizations that have access to launch the resulting AMI(s)."
  default     = []
}

variable "ami_users" {
  type        = list(string)
  description = "A list of account IDs that have access to launch the resulting AMI(s)."
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the built AMI."
  default     = {}
}

variable "run_tags" {
  type        = map(string)
  description = "Tags to apply to resources (key-pair, SG, IAM, snapshot, interfaces and instance) used when building the AMI."
  default     = {}
}