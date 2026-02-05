# Copyright 2026 Canonical Ltd.
# See LICENSE file for licensing details.

variable "cloud_name" {
  description = "name of cloud"
  type        = string
}

variable "kubeconfig_path" {
  type        = string
  description = "path to save kubeconfig to"
  default     = "../shared-configs/k8s_kubeconfig"
}

variable "storage_class_name" {
  type        = string
  description = "Specify the Kubernetes storage class name for workload and operator storage"
}

