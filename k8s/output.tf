output "kubeconfig_file_path" {
  value       = abspath("${path.root}/${var.kubeconfig_path}")
  description = "The absolute path to the generated kubeconfig"
}