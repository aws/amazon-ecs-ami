locals {
  ami_name_al2 = "${var.ami_name_prefix_al2}-hvm-2.0.${var.ami_version}-x86_64-ebs"
}

source "amazon-ebs" "al2" {
  ami_name        = "${local.ami_name_al2}"
  ami_description = "Amazon Linux AMI 2.0.${var.ami_version} x86_64 ECS HVM GP2"
  instance_type   = var.general_purpose_instance_types[0]
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
    ami_type            = "al2"
    ami_version         = "2.0.${var.ami_version}"
  }
}

build {
  sources = [
    "source.amazon-ebs.al2",
    "source.amazon-ebs.al2arm",
    "source.amazon-ebs.al2gpu",
    "source.amazon-ebs.al2keplergpu",
    "source.amazon-ebs.al2inf",
    "source.amazon-ebs.al2kernel5dot10",
    "source.amazon-ebs.al2kernel5dot10arm"
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

  provisioner "file" {
    source      = "files/29-ecs-banner-begin.sh.amzn2"
    destination = "/tmp/29-ecs-banner-begin"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/29-ecs-banner-begin /etc/update-motd.d/29-ecs-banner-begin",
      "sudo chmod 755 /etc/update-motd.d/29-ecs-banner-begin"
    ]
  }

  provisioner "file" {
    source      = "files/31-ecs-banner-finish.sh.amzn2"
    destination = "/tmp/31-ecs-banner-finish"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/31-ecs-banner-finish /etc/update-motd.d/31-ecs-banner-finish",
      "sudo chmod 755 /etc/update-motd.d/31-ecs-banner-finish"
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
      "sudo yum install -y ${local.packages_al2}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
    environment_vars = [
      "DOCKER_VERSION=${var.docker_version}",
      "CONTAINERD_VERSION=${var.containerd_version}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
  }

  # the ordering matters here, this repo is installed after docker is installed
  # so that the docker extras repo is overwritten in the final AMI.
  provisioner "file" {
    source      = "files/repos/amzn2-extras.repo"
    destination = "/tmp/amzn2-extras.repo"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/amzn2-extras.repo /etc/yum.repos.d/amzn2-extras.repo"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-ecs-init.sh"
    environment_vars = [
      "REGION=${var.region}",
      "AGENT_VERSION=${var.ecs_agent_version}",
      "INIT_REV=${var.ecs_init_rev}",
      "AL_NAME=amzn2",
      "AIR_GAPPED=${var.air_gapped}",
      "ECS_INIT_URL=${var.ecs_init_url_al2}",
      "ECS_INIT_LOCAL_OVERRIDE=${var.ecs_init_local_override}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-managed-daemons.sh"
    environment_vars = [
      "REGION=${var.region}",
      "AGENT_VERSION=${var.ecs_agent_version}",
      "AIR_GAPPED=${var.air_gapped}",
      "MANAGED_DAEMON_BASE_URL=${var.managed_daemon_base_url}"
    ]
  }

  provisioner "shell" {
    script = "scripts/install-additional-packages.sh"
  }

  provisioner "file" {
    source      = "files/amazon-ssm-agent.gpg"
    destination = "/tmp/amazon-ssm-agent.gpg"
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
    script = "scripts/append-efs-client-info.sh"
  }

  provisioner "shell" {
    environment_vars = ["AMI_TYPE=${source.name}"]
    script           = "scripts/enable-ecs-agent-inferentia-support.sh"
  }

  provisioner "shell" {
    environment_vars = ["AMI_TYPE=${source.name}"]
    script           = "scripts/al2/install-kernel5dot10.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "AMI_TYPE=${source.name}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
    script = "scripts/enable-ecs-agent-gpu-support.sh"
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
    script = "scripts/install-service-connect-appnet.sh"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo yum update -y --security --sec-severity=critical --exclude=nvidia*,docker*,cuda*,containerd*"
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
