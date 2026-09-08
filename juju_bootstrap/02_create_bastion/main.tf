# Create a Bastion Container
resource "lxd_instance" "bastion" {
  name     = var.bastion_name
  project  = var.lxd_project_name_juju
  image    = "ubuntu:${var.ubuntu_version}"
  type     = "container"
  profiles = ["default"]

  config = {
    "boot.autostart"   = true
    "security.nesting" = true

    "cloud-init.user-data" = <<-EOF
      #cloud-config
      ssh_authorized_keys:
        - ${trimspace(file(pathexpand(var.ssh_public_key)))}
      package_update: true
      package_upgrade: true
      snap:
        commands:
          - snap install juju --channel=${var.juju_channel}
          - snap install lxd --channel=${var.lxd_channel}
          - snap install terraform --classic
          - snap install yq
          - snap install kubectl --classic
    EOF

    "cloud-init.network-config" = trimspace(var.bastion_network_config)
  }

  execs = {
    wait_cloud_init = {
      command       = ["cloud-init", "status", "--wait"]
      fail_on_error = true
      trigger       = "once"
    }
  }

  timeouts = {
    create = "10m"
  }
}

resource "lxd_instance_file" "juju_ops_public_key" {
  depends_on  = [lxd_instance.bastion]
  project     = var.lxd_project_name_juju
  instance    = lxd_instance.bastion.name
  source_path = pathexpand("${path.module}/../tls/${var.lxd_juju_operator_username}.crt")
  target_path = "/home/ubuntu/${var.lxd_juju_operator_username}.crt"
  uid         = "1000"
  gid         = "1000"
  mode        = "0644"
}

resource "lxd_instance_file" "juju_ops_private_key" {
  depends_on  = [lxd_instance.bastion]
  project     = var.lxd_project_name_juju
  instance    = lxd_instance.bastion.name
  source_path = pathexpand("${path.module}/../tls/${var.lxd_juju_operator_username}.key")
  target_path = "/home/ubuntu/${var.lxd_juju_operator_username}.key"
  uid         = "1000"
  gid         = "1000"
  mode        = "0600"
}
