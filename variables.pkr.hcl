packer {
  required_plugins {
    amazon = {
      version = "1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  packages_al2    = "amazon-efs-utils ec2-net-utils acpid amazon-ssm-agent yum-plugin-upgrade-helper iproute-tc"
  packages_al2023 = "amazon-efs-utils amazon-ssm-agent amazon-ec2-net-utils acpid iproute-tc ec2-instance-connect"
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
  default     = "1.100.0"
}

variable "ecs_init_rev" {
  type        = string
  description = "ecs-init package version rev"
  default     = "1"
}

variable "docker_version" {
  type        = string
  description = "Docker version to build AMI with."
  default     = "25.0.13"
}

variable "containerd_version" {
  type        = string
  description = "Containerd version to build AMI with."
  default     = "2.1.4"
}

variable "runc_version" {
  type        = string
  description = "Runc version to build AMI with."
  default     = "1.3.1"
}

variable "docker_version_al2023" {
  type        = string
  description = "Docker version to build AL2023 AMI with."
  default     = "25.0.8"
}

variable "containerd_version_al2023" {
  type        = string
  description = "Containerd version to build AL2023 AMI with."
  default     = "2.0.5"
}

variable "runc_version_al2023" {
  type        = string
  description = "Runc version to build AL2023 AMI with."
  default     = "1.2.6"
}

variable "exec_ssm_version" {
  type        = string
  description = "SSM binary version to build ECS exec support with."
  default     = "3.3.3050.0"
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

variable "kernel_version_al2023" {
  type        = string
  description = "Amazon Linux 2023 kernel version."
}

variable "kernel_version_al2023arm" {
  type        = string
  description = "Amazon Linux 2023 ARM kernel version."
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

variable "general_purpose_instance_type" {
  type        = string
  description = "Instance type used to build for general-purpose platform"
  default     = "c5.large"
}

variable "gpu_instance_type" {
  type        = string
  description = "Instance type used to build for GPU platform"
  default     = "c5.4xlarge"
}

variable "arm_instance_type" {
  type        = string
  description = "Instance type used to build for ARM platform"
  default     = "m6g.xlarge"
}

variable "inf_instance_type" {
  type        = string
  description = "Instance type used to build for INF platform"
  default     = "inf1.xlarge"
}

variable "neu_instance_type" {
  type        = string
  description = "Instance type used to build for NEU platform"
  default     = "inf1.xlarge"
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

variable "region_dns_suffix" {
  type        = string
  description = "DNS Suffix to use for in region URLs"
  default     = ""
}

variable "custom_endpoint_ec2" {
  type        = string
  description = "Custom EC2 endpoint to use for building AMIs"
  default     = ""
}
