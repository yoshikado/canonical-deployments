variable "juju_controller_name" {
  description = "The name of the Juju controller."
  type        = string
  default     = "microcloud-controller"
}

variable "lxd_project_name_juju" {
  description = "The name of the LXD project for Juju."
  type        = string
  default     = "juju"
}

variable "controller_nic_name" {
  description = "Network interface name inside the controller VMs."
  type        = string
  default     = "enp5s0"
}

variable "controller_gateway" {
  description = "Default gateway for the controller VMs."
  type        = string
  default     = "192.168.151.1"
}

variable "controller_nameservers" {
  description = "List of DNS nameservers for the controller VMs."
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "node2_zone" {
  description = "Target cluster member/zone for HA node 2 (e.g. vm02)."
  type        = string
  default     = "vm02"
}

variable "node2_ip_cidr" {
  description = "Static IP address in CIDR format for HA node 2."
  type        = string
  default     = "192.168.151.202/24"
}

variable "node2_constraints" {
  description = "Machine constraints for HA node 2."
  type        = string
  default     = "cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm02"
}

variable "node3_zone" {
  description = "Target cluster member/zone for HA node 3 (e.g. vm03)."
  type        = string
  default     = "vm03"
}

variable "node3_ip_cidr" {
  description = "Static IP address in CIDR format for HA node 3."
  type        = string
  default     = "192.168.151.203/24"
}

variable "node3_constraints" {
  description = "Machine constraints for HA node 3."
  type        = string
  default     = "cores=2 mem=4G root-disk=20G root-disk-source=remote virt-type=virtual-machine zones=vm03"
}

# --- Juju Controller HA Configuration ---

variable "ha_units" {
  description = "Desired number of controller units (must be odd and >= 3)."
  type        = number
  default     = 3
}

variable "ha_to" {
  description = "Optional list of placement directives for new controller units (e.g. [\"1\", \"2\"])."
  type        = list(string)
  default     = ["1", "2"]
}

variable "ha_constraints" {
  description = "Optional placement constraints for newly provisioned controller units (e.g. \"mem=8G cores=4\")."
  type        = string
  default     = null
}
