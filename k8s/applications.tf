resource "juju_application" "logrotated" {
  name  = var.logrotated_config.app_name

  model = juju_model.k8s.name

  charm {
    name    = "logrotated"
    base    = var.logrotated_config.base
    channel = var.logrotated_config.channel
  }

  config = var.logrotated_config.config
}
