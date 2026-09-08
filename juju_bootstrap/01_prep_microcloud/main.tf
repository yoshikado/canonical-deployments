# Create project for juju
resource "lxd_project" "juju_project" {
  name        = var.lxd_project_name_juju
  description = "Project for juju"
  config = {
    "restricted"                    = var.lxd_project_restricted_juju
    "restricted.devices.nic"        = var.lxd_project_restricted_devices_nic
    "restricted.networks.access"    = var.lxd_project_restricted_networks_access
    "restricted.cluster.target"     = var.lxd_project_restricted_cluster_target
    "restricted.containers.nesting" = var.lxd_project_restricted_containers_nesting
  }
}


# Update default profile in juju project
resource "lxd_profile" "juju_default" {
  depends_on = [lxd_project.juju_project]
  name       = "default"
  project    = var.lxd_project_name_juju

  config = {}

  device {
    type = "nic"
    name = "eth0"
    properties = {
      name    = "eth0"
      nictype = "bridged"
      parent  = var.lxd_bridge_name
      mtu     = "1500"
    }
  }

  device {
    type = "disk"
    name = "root"
    properties = {
      pool = "remote" # default Ceph pool name for MicroCloud
      path = "/"
    }
  }
}


# Update and create permissions for juju
resource "lxd_auth_group" "juju_group" {
  name = var.lxd_auth_group_name_juju
  permissions = [
    {
      entitlement = "operator"
      entity_type = "project"
      entity_args = {
        name = lxd_project.juju_project.name
      }
    },
    {
      entitlement = "can_view_unmanaged_networks"
      entity_type = "server"
      entity_args = {}
    },
    {
      entitlement = "viewer"
      entity_type = "server"
      entity_args = {}
    }
  ]
}


# Create a user for juju project
# Generate private key for the client
resource "tls_private_key" "juju_operator_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

# Generate self-signed client certificate
resource "tls_self_signed_cert" "juju_operator_cert" {
  private_key_pem = tls_private_key.juju_operator_key.private_key_pem

  subject {
    common_name  = var.lxd_juju_operator_username
    organization = "Juju"
  }

  validity_period_hours = 87600 # 10 years

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "client_auth",
  ]
}

# Save certificate and key to disk (optional: for Juju / lxc client to use)
resource "local_file" "juju_operator_cert" {
  content  = tls_self_signed_cert.juju_operator_cert.cert_pem
  filename = "${path.module}/../tls/${var.lxd_juju_operator_username}.crt"
}

resource "local_sensitive_file" "juju_operator_key" {
  content         = tls_private_key.juju_operator_key.private_key_pem
  filename        = "${path.module}/../tls/${var.lxd_juju_operator_username}.key"
  file_permission = "0600"
}

# Create TLS user in LXD
resource "lxd_auth_identity" "juju-operator-user" {
  depends_on      = [lxd_auth_group.juju_group]
  auth_method     = "tls"
  name            = var.lxd_juju_operator_username
  groups          = [lxd_auth_group.juju_group.name]
  tls_certificate = tls_self_signed_cert.juju_operator_cert.cert_pem
  remote          = var.lxd_remote_name
}
