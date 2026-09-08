terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

provider "lxd" {
  remote {
    name    = var.lxd_remote_name
    address = var.lxd_remote_url
  }
}
