locals {
  ami_name_al2arm = "${var.ami_name_prefix_al2}-hvm-2.0.${var.ami_version}-arm64-ebs"
}

source "amazon-ebs" "al2arm" {
  ami_name        = "${local.ami_name_al2arm}"
  ami_description = "Amazon Linux AMI 2.0.${var.ami_version} arm64 ECS HVM GP3"
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
      name = "${var.source_ami_al2arm}"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  ssh_username = "ec2-user"
  tags = {
    os_version          = "Amazon Linux 2"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2arm"
    ami_version         = "2.0.${var.ami_version}"
  }
}
