variable "model_name" {
  description = "name of model to deploy onto"
  type        = string
}

variable "k8s_config" {
  description = "configuration for the k8s charm"
  type = object({
    app_name    = optional(string, "k8s")
    base        = string
    channel     = string
    config      = optional(map(string), {})
    constraints = optional(string)
    resources   = optional(map(string))
    revision    = optional(number)
    units       = number
    machines    = optional(set(string))
  })
}

variable "k8s_worker_config" {
  description = "configuration for the k8s-worker charm"
  type = object({
    app_name    = optional(string, "k8s-worker")
    base        = string
    channel     = string
    config      = optional(map(string), {})
    constraints = optional(string)
    resources   = optional(map(string))
    revision    = optional(number)
    units       = number
    machines    = optional(set(string))
  })
}
variable "kubeconfig_path" {
  type        = string
  description = "path to save kubeconfig to. relative to project directory."
  default     = "../shared-configs/k8s_kubeconfig"
}

variable "logrotated_config" {
  description = "configuration for the logrotated charm"
  type = object({
    app_name    = optional(string, "logrotated")
    base        = string
    channel     = string
    config      = optional(map(string), {})
  })
}