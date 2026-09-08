# Bootstrap Juju controller and configure static IP for the controller VM
resource "terraform_data" "juju_bootstrap" {
  input = {
    cloud_name                 = var.juju_cloud_name
    controller_name            = var.juju_controller_name
    bootstrap_constraints      = var.bootstrap_constraints
    bootstrap_target           = var.bootstrap_target
    lxd_project                = var.lxd_project_name_juju
    nic_name                   = var.controller_nic_name
    ip_cidr                    = var.controller_ip_cidr
    gateway                    = var.controller_gateway
    nameservers                = join(" ", var.controller_nameservers)
    lxd_remote_name            = var.lxd_remote_name
    lxd_remote_url             = var.lxd_remote_url
    lxd_juju_operator_username = var.lxd_juju_operator_username
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/bootstrap.sh"

    environment = {
      JUJU_CLOUD_NAME            = var.juju_cloud_name
      JUJU_CONTROLLER_NAME       = var.juju_controller_name
      BOOTSTRAP_CONSTRAINTS      = var.bootstrap_constraints
      BOOTSTRAP_TARGET           = var.bootstrap_target
      LXD_PROJECT                = var.lxd_project_name_juju
      NIC_NAME                   = var.controller_nic_name
      IP_CIDR                    = var.controller_ip_cidr
      GATEWAY                    = var.controller_gateway
      NAMESERVERS                = join(" ", var.controller_nameservers)
      LXD_REMOTE_NAME            = var.lxd_remote_name
      LXD_REMOTE_URL             = var.lxd_remote_url
      LXD_JUJU_OPERATOR_USERNAME = var.lxd_juju_operator_username
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      juju destroy-controller ${self.input.controller_name} --no-prompt --destroy-all-models --destroy-storage
      lxc remote switch local
      lxc remote remove ${self.input.lxd_remote_name}
      rm ~/snap/lxd/common/config/client.*
    EOF
  }
}

output "controller_name" {
  description = "The name of the bootstrapped Juju controller."
  value       = var.juju_controller_name
}

output "cloud_name" {
  description = "The name of the cloud the controller was bootstrapped on."
  value       = var.juju_cloud_name
}

output "controller_ip" {
  description = "The static IP assigned to the controller VM."
  value       = var.controller_ip_cidr
}

