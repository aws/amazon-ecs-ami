locals {
  ami_name_al2gpu = "${var.ami_name_prefix_al2}-gpu-hvm-2.0.${var.ami_version}-x86_64-ebs"
}

source "amazon-ebs" "al2gpu" {
  ami_name            = "${local.ami_name_al2gpu}"
  ami_description     = "Amazon Linux AMI 2.0.${var.ami_version} x86_64 ECS HVM GP2"
  spot_instance_types = var.gpu_instance_types
  spot_price          = "auto"
  launch_block_device_mappings {
    volume_size           = var.block_device_size_gb
    delete_on_termination = true
    volume_type           = "gp2"
    device_name           = "/dev/xvda"
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al2}"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  ssh_interface = "public_ip"
  ssh_username  = "ec2-user"
  tags = {
    os_version          = "Amazon Linux 2"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2gpu"
    ami_version         = "2.0.${var.ami_version}"
  }
}
