locals {
  ami_name_al2023 = "hardened-ecs-container-instance-unverified-al2-image-${formatdate("YYYY-MM-DD", timestamp())}"
  default_tags = {
    os_version          = "Amazon Linux 2023"
    source_image_name   = "{{ .SourceAMIName }}"
    ecs_runtime_version = "Docker version ${var.docker_version_al2023}"
    ecs_agent_version   = "${var.ecs_agent_version}"
    ami_type            = "al2023"
    ami_version         = "2023.0.${var.ami_version_al2023}"
  }
  merged_tags = merge("${local.default_tags}", "${var.tags}")
}

source "amazon-ebs" "al2023" {
  ami_name        = "${local.ami_name_al2023}"
  ami_description = "Amazon Linux AMI 2023.0.${var.ami_version_al2023} x86_64 ECS HVM EBS"
  instance_type   = var.general_purpose_instance_types[0]
  launch_block_device_mappings {
    volume_size           = var.block_device_size_gb
    delete_on_termination = true
    volume_type           = "gp3"
    device_name           = "/dev/xvda"
    encrypted             = true
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" // This enforces IMDSv2
    http_put_response_hop_limit = 2
  }
  region = var.region
  source_ami_filter {
    filters = {
      name = "${var.source_ami_al2023}"
    }
    owners             = ["679593333241"]
    most_recent        = true
    include_deprecated = true
  }
  ami_ou_arns   = "${var.ami_ou_arns}"
  ami_org_arns  = "${var.ami_org_arns}"
  ami_users     = "${var.ami_users}"
  ssh_interface = "public_dns"
  ssh_username  = "ec2-user"
  tags          = "${local.merged_tags}"
  run_tags      = "${var.run_tags}"
  profile       = var.profile
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
}

build {
  sources = [
    "source.amazon-ebs.al2023",
    "source.amazon-ebs.al2023arm",
    "source.amazon-ebs.al2023neu",
    "source.amazon-ebs.al2023gpu"
  ]

  provisioner "file" {
    source      = "files/90_ecs.cfg.amzn2"
    destination = "/tmp/90_ecs.cfg"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo mv /tmp/90_ecs.cfg /etc/cloud/cloud.cfg.d/90_ecs.cfg",
      "sudo chown root:root /etc/cloud/cloud.cfg.d/90_ecs.cfg"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/al2023/setup-motd.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang = "/bin/sh -ex"
    inline = [
      "mkdir /tmp/additional-packages"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo dnf update -y --releasever=${var.distribution_release_al2023}"
    ]
  }

  provisioner "file" {
    source      = "additional-packages/"
    destination = "/tmp/additional-packages"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo dnf install -y ${local.packages_al2023}",
      "sudo dnf swap -y gnupg2-minimal gnupg2-full"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/setup-ecs-config-dir.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/install-docker.sh"
    environment_vars = [
      "DOCKER_VERSION=${var.docker_version_al2023}",
      "CONTAINERD_VERSION=${var.containerd_version_al2023}",
      "RUNC_VERSION=${var.runc_version_al2023}",
      "AIR_GAPPED=${var.air_gapped}"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/install-ecs-init.sh"
    environment_vars = [
      "REGION=${var.region}",
      "AGENT_VERSION=${var.ecs_agent_version}",
      "INIT_REV=${var.ecs_init_rev}",
      "AL_NAME=amzn2023",
      "ECS_INIT_URL=${var.ecs_init_url_al2023}",
      "AIR_GAPPED=${var.air_gapped}",
      "ECS_INIT_LOCAL_OVERRIDE=${var.ecs_init_local_override}"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/append-efs-client-info.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/install-additional-packages.sh"
  }

  ### exec

  provisioner "file" {
    source      = "files/amazon-ssm-agent.gpg"
    destination = "/tmp/amazon-ssm-agent.gpg"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/install-exec-dependencies.sh"
    environment_vars = [
      "AMI_TYPE=${source.name}",
      "REGION=${var.region}",
      "EXEC_SSM_VERSION=${var.exec_ssm_version}",
      "AIR_GAPPED=${var.air_gapped}",
      "REGION_DNS_SUFFIX=${var.region_dns_suffix}"
    ]
  }

  ### reboot worker instance to install kernel update. enable-ecs-agent-inferentia-support needs
  ### new kernel (if there is) to be installed.
  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang    = "/bin/sh -ex"
    expect_disconnect = "true"
    inline = [
      "sudo reboot"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "AMI_TYPE=${source.name}"
    ]
    pause_before        = "10s" # pause for starting the reboot
    start_retry_timeout = "40s" # wait before start retry
    max_retries         = 3
    execute_command     = "{{.Vars}} bash '{{.Path}}'"
    script              = "scripts/enable-ecs-agent-inferentia-support.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "AMI_TYPE=${source.name}"
    ]
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/enable-ecs-agent-gpu-support-al2023.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    inline_shebang = "/bin/sh -ex"
    inline = [
      "sudo usermod -a -G docker ec2-user"
    ]
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/enable-services.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/install-service-connect-appnet.sh"
  }

  provisioner "shell" {
    execute_command = "{{.Vars}} bash '{{.Path}}'"
    script = "scripts/cleanup.sh"
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
