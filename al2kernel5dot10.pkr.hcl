locals {
  ami_name_al2kernel5dot10 = "${var.ami_name_prefix_al2}-kernel-5.10-hvm-2.0.${var.ami_version_al2}-x86_64-ebs"
  default_tags = {
    os_version          = "Amazon Linux 2"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2kernel5dot10"
    ami_version         = "2.0.${var.ami_version_al2}"
  }
  merged_tags = merge("${local.default_tags}", "${var.tags}")
}

source "amazon-ebs" "al2kernel5dot10" {
  ami_name        = "${local.ami_name_al2kernel5dot10}"
  ami_description = "Amazon Linux AMI 2.0.${var.ami_version_al2} Kernel 5.10 x86_64 ECS HVM GP2"
  instance_type   = var.general_purpose_instance_types[0]
  launch_block_device_mappings {
    volume_size           = var.block_device_size_gb
    delete_on_termination = true
    volume_type           = "gp2"
    device_name           = "/dev/xvda"
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" // This enforces IMDSv2
    http_put_response_hop_limit = 2
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al2kernel5dot10}"
    }
    owners             = ["amazon"]
    most_recent        = true
    include_deprecated = true
  }
  ami_ou_arns   = "${var.ami_ou_arns}"
  ami_org_arns  = "${var.ami_org_arns}"
  ami_users     = "${var.ami_users}"
  ssh_interface = "public_ip"
  ssh_username  = "ec2-user"
  tags          = "${local.merged_tags}"
  run_tags      = "${var.run_tags}"
}
