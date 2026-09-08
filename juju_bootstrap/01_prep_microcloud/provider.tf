terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "lxd" {
  remote {
    name    = var.lxd_remote_name
    address = var.lxd_remote_url
  }
}
