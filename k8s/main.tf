resource "juju_model" "k8s" {
  name = var.model_name
}

module "k8s" {
  source      = "git::https://github.com/canonical/k8s-operator//charms/worker/k8s/terraform"
  app_name = var.k8s_config.app_name
  channel  = var.k8s_config.channel
  config = merge(
    var.k8s_config.config,
  )
  constraints = var.k8s_config.constraints
  model       = juju_model.k8s.name
  resources   = var.k8s_config.resources
  revision    = var.k8s_config.revision
  base        = var.k8s_config.base
  units       = var.k8s_config.units
}

module "k8s_worker" {
  source      = "git::https://github.com/canonical/k8s-operator//charms/worker/terraform"
  app_name = var.k8s_worker_config.app_name
  channel  = var.k8s_worker_config.channel
  config = merge(
    var.k8s_worker_config.config,
  )
  constraints = var.k8s_worker_config.constraints
  model       = juju_model.k8s.name
  resources   = var.k8s_worker_config.resources
  revision    = var.k8s_worker_config.revision
  base        = var.k8s_worker_config.base
  units       = var.k8s_worker_config.units
}

resource "terraform_data" "juju_wait" {
  depends_on = [module.k8s,module.k8s_worker]
  provisioner "local-exec" {
    command = "juju wait-for model ${var.model_name} --query='forEach(units, unit => unit.workload-status==\"active\")' --timeout 60m --summary"
  }
}

resource "terraform_data" "kubeconfig" {
  depends_on = [terraform_data.juju_wait]
  triggers_replace = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
      # 1. Create the directory (dirname extracts the folder path)
      mkdir -p $(dirname ${abspath("${path.root}/${var.kubeconfig_path}")})
      
      # 2. Generate and save the kubeconfig
      juju run -m ${var.model_name} ${var.k8s_config.app_name}/leader get-kubeconfig --format json | \
        jq -r '.[].results.kubeconfig' | \
        tee ${abspath("${path.root}/${var.kubeconfig_path}")}
    EOT
  }
}