locals {
  ami_name_al1 = "${var.ami_name_prefix_al1}${var.ami_version}-amazon-ecs-optimized"
}

source "amazon-ebs" "al1" {
  ami_name            = "${local.ami_name_al1}"
  ami_description     = "Amazon Linux AMI amzn-ami-2018.03.${var.ami_version} x86_64 ECS HVM GP2"
  spot_instance_types = var.general_purpose_instance_types
  spot_price          = "auto"
  launch_block_device_mappings {
    volume_size           = 8
    delete_on_termination = true
    volume_type           = "gp2"
    device_name           = "/dev/xvda"
  }
  launch_block_device_mappings {
    volume_size           = 22
    delete_on_termination = true
    volume_type           = "gp2"
    device_name           = "/dev/xvdcz"
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al1}"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  user_data_file = "scripts/al1/user_data.sh"
  ssh_interface  = "public_ip"
  ssh_username   = "ec2-user"
  tags = {
    os_version          = "Amazon Linux"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version_al1}"
    ecs_agent_version   = "${var.ecs_version_al1}"
    ami_type            = "al1"
    ami_version         = "2018.03.${var.ami_version}"
  }
}

build {
  sources = [
    "source.amazon-ebs.al1"
  ]

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done"
    ]
  }

  provisioner "file" {
    source      = "files/al1/90_ecs.cfg"
    destination = "/tmp/90_ecs.cfg"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/90_ecs.cfg /etc/cloud/cloud.cfg.d/90_ecs.cfg"
    ]
  }

  provisioner "file" {
    source      = "files/al1/ecs-custom-motd"
    destination = "/tmp/ecs-custom-motd"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/ecs-custom-motd /etc/update-motd.d/30-banner",
      "sudo chmod 755 /etc/update-motd.d/30-banner"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "mkdir /tmp/additional-packages"
    ]
  }

  provisioner "file" {
    source      = "additional-packages/"
    destination = "/tmp/additional-packages"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo yum install -y docker-${var.docker_version_al1} ecs-init-${var.ecs_version_al1} ${local.packages_al1}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-additional-packages.sh"
  }

  provisioner "shell" {
    script = "scripts/install-exec-dependencies.sh"
    environment_vars = [
      "REGION=${var.region}",
      "EXEC_SSM_VERSION=${var.exec_ssm_version}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
  }

  provisioner "shell" {
    script = "scripts/al1/configure-docker-storage-setup.sh"
  }

  provisioner "shell" {
    script = "scripts/al1/unlock-releasever.sh"
  }

  provisioner "shell" {
    script = "scripts/al1/check-ownership.sh"
  }

  provisioner "shell" {
    script = "scripts/append-efs-client-info.sh"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo usermod -a -G docker ec2-user"
    ]
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
