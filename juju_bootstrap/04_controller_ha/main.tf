# Read controller connection info & credentials from Juju client configuration
# (automatically created during bootstrap in 03_bootstrap), with fallbacks to variables.
locals {
  juju_controllers_file = pathexpand("~/.local/share/juju/controllers.yaml")
  juju_accounts_file    = pathexpand("~/.local/share/juju/accounts.yaml")

  ca_cert       = var.controller_ca_cert != "" ? var.controller_ca_cert : try(yamldecode(file(local.juju_controllers_file)).controllers[var.juju_controller_name]["ca-cert"], "")
  password      = var.controller_password != "" ? var.controller_password : try(yamldecode(file(local.juju_accounts_file)).controllers[var.juju_controller_name]["password"], "")
  api_addresses = length(var.controller_api_addresses) > 0 ? var.controller_api_addresses : try(yamldecode(file(local.juju_controllers_file)).controllers[var.juju_controller_name]["api-endpoints"], ["192.168.151.201:17070"])
}

# 1. Prepare HA nodes (machines 1 and 2) with static IPs
# Since MicroCloud bridge network has no DHCP, new controller VMs must have
# static IPs configured via Netplan before Juju agent can connect to the controller.
resource "terraform_data" "prepare_ha_nodes" {
  input = {
    controller_name   = var.juju_controller_name
    lxd_project       = var.lxd_project_name_juju
    nic_name          = var.controller_nic_name
    gateway           = var.controller_gateway
    nameservers       = join(" ", var.controller_nameservers)
    node2_zone        = var.node2_zone
    node2_ip_cidr     = var.node2_ip_cidr
    node2_constraints = var.node2_constraints
    node3_zone        = var.node3_zone
    node3_ip_cidr     = var.node3_ip_cidr
    node3_constraints = var.node3_constraints
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/prepare_nodes.sh"

    environment = {
      JUJU_CONTROLLER_NAME = var.juju_controller_name
      LXD_PROJECT          = var.lxd_project_name_juju
      NIC_NAME             = var.controller_nic_name
      GATEWAY              = var.controller_gateway
      NAMESERVERS          = join(" ", var.controller_nameservers)
      NODE2_CONSTRAINTS    = var.node2_constraints
      NODE2_IP_CIDR        = var.node2_ip_cidr
      NODE3_CONSTRAINTS    = var.node3_constraints
      NODE3_IP_CIDR        = var.node3_ip_cidr
    }
  }

  lifecycle {
    action_trigger {
      events  = [after_create]
      actions = [action.juju_enable_ha.controller_ha]
    }
  }
}

# 2. Enable HA using the Juju Terraform Provider action
action "juju_enable_ha" "controller_ha" {
  config {
    api_addresses = local.api_addresses
    ca_cert       = local.ca_cert
    username      = var.controller_username
    password      = local.password
    units         = var.ha_units
    to            = var.ha_to
    constraints   = var.ha_constraints
  }
}

output "controller_name" {
  description = "The name of the HA Juju controller."
  value       = var.juju_controller_name
}

output "node2_ip" {
  description = "Static IP of HA controller node 2."
  value       = var.node2_ip_cidr
}

output "node3_ip" {
  description = "Static IP of HA controller node 3."
  value       = var.node3_ip_cidr
}
