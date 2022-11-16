locals {
  ami_name_al2022arm = "${var.ami_name_prefix_al2022}-hvm-2022.0.${var.ami_version}${var.kernel_version_al2022arm}-arm64"
}

source "amazon-ebs" "al2022arm" {
  ami_name        = "${local.ami_name_al2022arm}"
  ami_description = "Amazon Linux AMI 2022.0.${var.ami_version} arm64 ECS HVM EBS"
  instance_type   = "m6g.xlarge"
  launch_block_device_mappings {
    volume_size           = var.block_device_size_gb
    delete_on_termination = true
    volume_type           = "gp3"
    device_name           = "/dev/xvda"
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al2022arm}"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  ssh_username = "ec2-user"
  tags = {
    os_version          = "Amazon Linux 2022"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version_al2022}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2022arm"
    ami_version         = "2022.0.${var.ami_version}"
  }
}
