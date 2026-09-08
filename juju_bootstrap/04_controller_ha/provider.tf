terraform {
  required_version = ">= 1.14.0"

  required_providers {
    juju = {
      source  = "juju/juju"
      version = ">= 2.3.0"
    }
  }
}

provider "juju" {
  controller_mode = true
}
