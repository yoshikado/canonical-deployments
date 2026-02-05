resource "juju_kubernetes_cloud" "k8s" {
  name               = var.cloud_name
  kubernetes_config  = file(var.kubeconfig_path)
  storage_class_name = var.storage_class_name
}