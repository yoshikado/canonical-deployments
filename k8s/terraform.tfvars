model_name = "k8s"

k8s_config = {
  app_name    = "k8s"
  base        = "ubuntu@24.04"
  channel     = "1.32/stable"
  constraints = "arch=amd64 tags=k8s"
  units       = 3
  config      = {
    bootstrap-datastore          = "managed-etcd"
    bootstrap-pod-cidr           = "10.136.0.0/16"
    bootstrap-service-cidr       = "10.137.0.0/16"
    dns-upstream-nameservers     = "8.8.8.8 8.8.4.4"
    gateway-enabled              = true
    ingress-enabled              = true
    load-balancer-enabled        = true
    load-balancer-l2-mode        = true
    load-balancer-cidrs          = "192.168.10.35-192.168.10.39"
    local-storage-enabled        = true
    local-storage-reclaim-policy = "Retain"
  }
}

k8s_worker_config = {
  app_name    = "k8s-worker"
  base        = "ubuntu@24.04"
  channel     = "1.32/stable"
  constraints = "arch=amd64 tags=k8s"
  units       = 2
}

logrotated_config = {
  app_name    = "logrotated"
  base        = "ubuntu@24.04"
  channel     = "latest/stable"
  config      = {
    logrotate-retention = 7
  }
}
