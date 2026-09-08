variable "lxd_remote_name" {
  description = "The name of the LXD remote to use."
  type        = string
  default     = "microcloud"
}

variable "lxd_remote_url" {
  description = "The URL of the LXD remote to use."
  type        = string
  default     = "https://192.168.10.75:8443"
}

variable "lxd_project_name_juju" {
  description = "The name of the LXD project for Juju."
  type        = string
  default     = "juju"
}

variable "lxd_juju_operator_username" {
  description = "The name of the LXD user for Juju operator."
  type        = string
  default     = "juju-operator"
}

variable "juju_cloud_name" {
  description = "The name of the cloud to bootstrap the controller onto."
  type        = string
  default     = "microcloud"
}

variable "juju_controller_name" {
  description = "The name of the Juju controller."
  type        = string
  default     = "microcloud-controller"
}

variable "bootstrap_constraints" {
  description = "Constraints for the Juju controller instance."
  type        = string
  default     = "cores=4 mem=8G root-disk=60G root-disk-source=remote virt-type=virtual-machine"
}

variable "bootstrap_target" {
  description = "Target cluster member/host for placement (e.g., vm01)."
  type        = string
  default     = "vm01"
}

variable "controller_nic_name" {
  description = "Network interface name inside the controller VM."
  type        = string
  default     = "enp5s0"
}

variable "controller_ip_cidr" {
  description = "Static IP address in CIDR format for the controller VM."
  type        = string
  default     = "192.168.10.201/24"
}

variable "controller_gateway" {
  description = "Default gateway for the controller VM."
  type        = string
  default     = "192.168.10.1"
}

variable "controller_nameservers" {
  description = "List of DNS nameservers for the controller VM."
  type        = list(string)
  default     = ["8.8.8.8"]
}
