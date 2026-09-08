variable "lxd_remote_name" {
  description = "The name of the LXD remote to use."
}

variable "lxd_remote_url" {
  description = "The URL of the LXD remote to use."
}

variable "lxd_project_name_juju" {
  description = "The name of the project to create."
  default     = "juju"
}

variable "lxd_juju_operator_username" {
  description = "The name of the user to create."
  default     = "juju-operator"
}

variable "bastion_name" {
  description = "The name of the bastion container."
  default     = "bastion"
}

variable "ubuntu_version" {
  description = "The version of Ubuntu to use."
  default     = "24.04"
}

variable "ssh_public_key" {
  description = "The SSH public key to be added to authorized_keys in the bastion container."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "juju_channel" {
  description = "The snap channel for Juju."
  type        = string
  default     = "3/stable"
}

variable "lxd_channel" {
  description = "The snap channel for LXD."
  type        = string
  default     = "5.21/stable"
}

variable "bastion_network_config" {
  description = "The cloud-init network-config (Netplan v2) YAML for the bastion container."
  type        = string
  default     = <<-EOF
    version: 2
    ethernets:
      eth0:
        dhcp4: false
        dhcp6: false
        addresses: [192.168.151.200/24]
        routes:
        - to: default
          via: 192.168.151.1
        nameservers:
          addresses:
            - 1.1.1.1
  EOF
}
