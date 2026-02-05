# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

resource "juju_model" "kubeflow" {
  name = var.model_name
  credential = var.cloud_name

  cloud {
    name = var.cloud_name
  }

}

module "kubeflow_mlflow" {
  source = "git::https://github.com/canonical/charmed-kubeflow-solutions//modules/kubeflow-mlflow?ref=track/1.10"

  risk                                  = var.kubeflow_mlflow_config.risk
  create_model                          = var.kubeflow_mlflow_config.create_model
  cos_configuration                     = var.kubeflow_mlflow_config.cos_configuration
  jupyter_ui_config                     = var.kubeflow_mlflow_config.jupyter_ui_config
  dex_connectors                        = var.kubeflow_mlflow_config.dex_connectors
  dex_static_username                   = var.kubeflow_mlflow_config.dex_static_username
  dex_static_password                   = var.kubeflow_mlflow_config.dex_static_password
  existing_opentelemetry_collector_name = var.kubeflow_mlflow_config.existing_opentelemetry_collector_name
  opentelemetry_collector_k8s_size      = var.kubeflow_mlflow_config.opentelemetry_collector_k8s_size
  katib_db_size                         = var.kubeflow_mlflow_config.katib_db_size
  kfp_db_size                           = var.kubeflow_mlflow_config.kfp_db_size
  minio_size                            = var.kubeflow_mlflow_config.minio_size
  mlmd_size                             = var.kubeflow_mlflow_config.mlmd_size
  kubeflow_profiles_security_policy     = var.kubeflow_mlflow_config.kubeflow_profiles_security_policy
  public_url                            = var.kubeflow_mlflow_config.public_url
  enable_mlflow_nodeport                = var.kubeflow_mlflow_config.enable_mlflow_nodeport
  mlflow_nodeport                       = var.kubeflow_mlflow_config.mlflow_nodeport
  mlflow_dashboard_link                 = var.kubeflow_mlflow_config.mlflow_dashboard_link
  mlflow_kserve_integration             = var.kubeflow_mlflow_config.mlflow_kserve_integration
  mlflow_minio_size                     = var.kubeflow_mlflow_config.mlflow_minio_size
  mlflow_mysql_size                     = var.kubeflow_mlflow_config.mlflow_mysql_size
}