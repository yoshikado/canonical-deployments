# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_integration" "k8s_cluster_integration" {
  model    = juju_model.k8s.name

  application {
    name     = module.k8s.app_name
    endpoint = module.k8s.provides.k8s_cluster
  }
  application {
    name     = module.k8s_worker.app_name
    endpoint = module.k8s_worker.requires.cluster
  }
}

resource "juju_integration" "k8s_containerd" {
  model    = juju_model.k8s.name

  application {
    name     = module.k8s.app_name
    endpoint = module.k8s.provides.containerd
  }
  application {
    name     = module.k8s_worker.app_name
    endpoint = module.k8s_worker.requires.containerd
  }
}

resource "juju_integration" "k8s_cos_worker_tokens" {
  model    = juju_model.k8s.name

  application {
    name     = module.k8s.app_name
    endpoint = module.k8s.provides.cos_worker_tokens
  }
  application {
    name     = module.k8s_worker.app_name
    endpoint = module.k8s_worker.requires.cos_tokens
  }
}

resource "juju_integration" "k8s_logrotated" {
  model    = juju_model.k8s.name

  application {
    name     = module.k8s.app_name
    endpoint = "juju-info"
  }
  application {
    name     = juju_application.logrotated.name
    endpoint = "juju-info"
  }
}

resource "juju_integration" "k8s_worker_logrotated" {
  model    = juju_model.k8s.name

  application {
    name     = module.k8s_worker.app_name
    endpoint = "juju-info"
  }
  application {
    name     = juju_application.logrotated.name
    endpoint = "juju-info"
  }
}
