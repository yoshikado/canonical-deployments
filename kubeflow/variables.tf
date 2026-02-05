variable "model_name" {
  description = "name of model to deploy onto"
  type        = string
  default     = "kubeflow" # At the moment this need to be "kubeflow"
}

variable "cloud_name" {
  description = "name of cloud"
  type        = string
}

variable "kubeflow_config" {
  description = "configuration for the kubeflow deployment"
  type = object({
    risk                                  = optional(string, "stable")
    create_model                          = optional(bool, false)
    cos_configuration                     = optional(bool)
    jupyter_ui_config                     = optional(map(string), {})
    dex_connectors                        = optional(string)
    dex_static_username                   = optional(string)
    dex_static_password                   = optional(string)
    existing_opentelemetry_collector_name = optional(string)
    opentelemetry_collector_k8s_size      = optional(string)
    katib_db_size                         = optional(string, "10G")
    kfp_db_size                           = optional(string, "10G")
    minio_size                            = optional(string, "10G")
    mlmd_size                             = optional(string, "10G")
    kubeflow_profiles_security_policy     = optional(string, "privileged")
    public_url                            = optional(string)
  })
}
