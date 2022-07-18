locals {
  ami_name_al2022 = "${var.ami_name_prefix_al2022}-hvm-2022.0.${var.ami_version}-x86_64-ebs"
}

source "amazon-ebs" "al2022" {
  ami_name        = "${local.ami_name_al2022}"
  ami_description = "Amazon Linux AMI 2022.0.${var.ami_version} x86_64 ECS HVM GP3"
  instance_type   = "c5.large"
  launch_block_device_mappings {
    volume_size           = var.block_device_size_gb
    delete_on_termination = true
    volume_type           = "gp3"
    device_name           = "/dev/xvda"
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al2022}"
    }
    owners      = ["amazon"]
    most_recent = true
  }
  user_data_file = "scripts/al2022/user-data.sh"
  ssh_username   = "ec2-user"
  tags = {
    os_version          = "Amazon Linux 2022"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version_al2022}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2022"
    ami_version         = "2022.0.${var.ami_version}"
  }
}

build {
  sources = [
    "source.amazon-ebs.al2022",
    "source.amazon-ebs.al2022arm"
  ]

  provisioner "file" {
    source      = "files/90_ecs.cfg.amzn2"
    destination = "/tmp/90_ecs.cfg"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/90_ecs.cfg /etc/cloud/cloud.cfg.d/90_ecs.cfg",
      "sudo chown root:root /etc/cloud/cloud.cfg.d/90_ecs.cfg"
    ]
  }

  provisioner "shell" {
    script = "scripts/al2022/setup-motd.sh"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "mkdir /tmp/additional-packages"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo dnf update -y --releasever=${var.distribution_release_al2022}"
    ]
  }

  provisioner "shell" {
    script = "scripts/al2022/install-workarounds.sh"
  }

  provisioner "file" {
    source      = "additional-packages/"
    destination = "/tmp/additional-packages"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo dnf install -y ${local.packages_al2022}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
    environment_vars = [
      "DOCKER_VERSION=${var.docker_version_al2022}",
      "CONTAINERD_VERSION=${var.containerd_version_al2022}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-ecs-init.sh"
    environment_vars = [
      "REGION=${var.region}",
      "AGENT_VERSION=${var.ecs_agent_version}",
      "INIT_REV=${var.ecs_init_rev}",
      "AL_NAME=amzn2022",
      "ECS_INIT_URL=${var.ecs_init_url_al2022}",
      "AIR_GAPPED=${var.air_gapped}",
      "ECS_INIT_LOCAL_OVERRIDE=${var.ecs_init_local_override}"
    ]
  }

  provisioner "shell" {
    script = "scripts/append-efs-client-info.sh"
  }

  ### exec
  provisioner "shell" {
    script = "scripts/install-exec-dependencies.sh"
    environment_vars = [
      "REGION=${var.region}",
      "EXEC_SSM_VERSION=${var.exec_ssm_version}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo usermod -a -G docker ec2-user"
    ]
  }

  provisioner "shell" {
    script = "scripts/enable-services.sh"
  }

  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
