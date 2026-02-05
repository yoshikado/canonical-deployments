# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_model" "kubeflow" {
  name = var.model_name
  credential = var.cloud_name

  cloud {
    name = var.cloud_name
  }

}

module "kubeflow" {
  source      = "git::https://github.com/canonical/charmed-kubeflow-solutions//modules/kubeflow?ref=track/1.10"

  risk                                  = var.kubeflow_config.risk
  create_model                          = var.kubeflow_config.create_model
  cos_configuration                     = var.kubeflow_config.cos_configuration
  jupyter_ui_config                     = var.kubeflow_config.jupyter_ui_config
  dex_connectors                        = var.kubeflow_config.dex_connectors
  dex_static_username                   = var.kubeflow_config.dex_static_username
  dex_static_password                   = var.kubeflow_config.dex_static_password
  existing_opentelemetry_collector_name = var.kubeflow_config.existing_opentelemetry_collector_name
  opentelemetry_collector_k8s_size      = var.kubeflow_config.opentelemetry_collector_k8s_size
  katib_db_size                         = var.kubeflow_config.katib_db_size
  kfp_db_size                           = var.kubeflow_config.kfp_db_size
  minio_size                            = var.kubeflow_config.minio_size
  mlmd_size                             = var.kubeflow_config.mlmd_size
  kubeflow_profiles_security_policy     = var.kubeflow_config.kubeflow_profiles_security_policy
  public_url                            = var.kubeflow_config.public_url
}