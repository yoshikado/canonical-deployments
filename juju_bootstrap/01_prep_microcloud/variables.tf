variable "lxd_remote_name" {
  description = "The name of the LXD remote to use."
}

variable "lxd_remote_url" {
  description = "The URL of the LXD remote to use."
}

variable "lxd_bridge_name" {
  description = "The name of the LXD bridge to use."
  default     = "broam"
}

variable "lxd_project_name_juju" {
  description = "The name of the project to create."
  default     = "juju"
}

variable "lxd_project_restricted_juju" {
  description = "The restricted setting for the juju project."
  default     = "true"
}

variable "lxd_project_restricted_devices_nic" {
  description = "The restricted devices setting for the juju project. Choose from allow,managed or block"
  default     = "allow"
}

variable "lxd_project_restricted_networks_access" {
  description = "The restricted networks access setting for the juju project. Specify a comma-delimited list of network names that are allowed for use"
  default     = "broam"
}

variable "lxd_project_restricted_cluster_target" {
  description = "The restricted cluster target setting for the juju project. Choose from allow or block"
  default     = "allow"
}

variable "lxd_project_restricted_containers_nesting" {
  description = "The restricted containers nesting setting for the juju project. Choose from allow or block"
  default     = "allow"
}

variable "lxd_auth_group_name_juju" {
  description = "The name of the auth group to create."
  default     = "juju-operator"
}

variable "lxd_juju_operator_username" {
  description = "The name of the user to create."
  default     = "juju-operator"
}
