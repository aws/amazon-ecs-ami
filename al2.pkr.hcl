locals {
  ami_name_al2 = "${var.ami_name_prefix_al2}-hvm-2.0.${var.ami_version_al2}-x86_64-ebs"
  motd_files = [
    "29-ecs-banner-begin",
    "31-ecs-banner-finish",
    "69-available-updates-begin",
    "71-available-updates-finish"
  ]
  default_tags = {
    os_version          = "Amazon Linux 2"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2"
    ami_version         = "2.0.${var.ami_version_al2}"
  }
  merged_tags = merge("${local.default_tags}", "${var.tags}")
}

source "amazon-ebs" "al2" {
  ami_name            = "${local.ami_name_al2}"
  ami_description     = "Amazon Linux AMI 2.0.${var.ami_version_al2} x86_64 ECS HVM GP2"
  instance_type       = var.general_purpose_instance_type
  custom_endpoint_ec2 = var.custom_endpoint_ec2
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
      name = "${var.source_ami_al2}"
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

build {
  sources = [
    "source.amazon-ebs.al2",
    "source.amazon-ebs.al2arm",
    "source.amazon-ebs.al2gpu",
    "source.amazon-ebs.al2keplergpu",
    "source.amazon-ebs.al2inf",
    "source.amazon-ebs.al2kernel5dot10",
    "source.amazon-ebs.al2kernel5dot10arm",
    "source.amazon-ebs.al2kernel5dot10gpu",
    "source.amazon-ebs.al2kernel5dot10inf"
  ]

  provisioner "file" {
    source      = "scripts/functions.sh"
    destination = "/tmp/functions.sh"
  }

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

  dynamic "provisioner" {
    for_each = local.motd_files
    labels   = ["file"]
    content {
      source      = "files/${provisioner.value}.sh.amzn2"
      destination = "/tmp/${provisioner.value}"
    }
  }

  dynamic "provisioner" {
    for_each = local.motd_files
    labels   = ["shell"]
    content {
      inline_shebang = "/bin/sh -ex"
      inline = [
        "sudo mv /tmp/${provisioner.value} /etc/update-motd.d/${provisioner.value}",
        "sudo chmod 755 /etc/update-motd.d/${provisioner.value}"
      ]
    }
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
    script = "scripts/setup-ecs-config-dir.sh"
  }

  provisioner "shell" {
    script = "scripts/install-docker.sh"
    environment_vars = [
      "DOCKER_VERSION=${var.docker_version}",
      "CONTAINERD_VERSION=${var.containerd_version}",
      "RUNC_VERSION=${var.runc_version}",
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
      "sudo mv /tmp/amzn2-extras.repo /etc/yum.repos.d/amzn2-extras.repo",
      "sudo chown root:root /etc/yum.repos.d/amzn2-extras.repo"
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
    script = "scripts/install-additional-packages.sh"
  }

  provisioner "file" {
    source      = "files/amazon-ssm-agent.gpg"
    destination = "/tmp/amazon-ssm-agent.gpg"
  }

  provisioner "shell" {
    script = "scripts/install-exec-dependencies.sh"
    environment_vars = [
      "AMI_TYPE=${source.name}",
      "REGION=${var.region}",
      "EXEC_SSM_VERSION=${var.exec_ssm_version}",
      "AIR_GAPPED=${var.air_gapped}",
      "REGION_DNS_SUFFIX=${var.region_dns_suffix}"
    ]
  }

  provisioner "shell" {
    script = "scripts/append-efs-client-info.sh"
  }

  provisioner "shell" {
    environment_vars = ["AMI_TYPE=${source.name}"]
    script           = "scripts/al2/install-kernel5dot10.sh"
  }

  ### If necessary, reboot worker instance to install kernel update for enable-ecs-agent-inferentia-support or
  ### enable-ecs-agent-gpu-support scripts that factor in kernel version.
  provisioner "shell" {
    environment_vars  = ["AMI_TYPE=${source.name}"]
    expect_disconnect = "true"
    script            = "scripts/al2/reboot-for-kernel-upgrade.sh"
  }

  provisioner "shell" {
    environment_vars = ["AMI_TYPE=${source.name}"]
    pause_before     = "10s" # pause for starting the reboot
    script           = "scripts/enable-ecs-agent-inferentia-support.sh"
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

  provisioner "file" {
    source      = "amazon-ecs-logs-collector"
    destination = "/tmp"
  }

  provisioner "shell" {
    script = "scripts/install-ecs-logs-collector.sh"
  }

  provisioner "shell" {
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo yum update -y --security --sec-severity=critical --exclude=nvidia*,docker*,cuda*,containerd*,runc*"
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
