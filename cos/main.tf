resource "juju_model" "cos" {
  name = var.model_name

  credential = var.cloud_name

  cloud {
    name = var.cloud_name
  }
}

module "cos-lite" {
  source     = "git::https://github.com/canonical/observability-stack//terraform/cos-lite?ref=track/2"
  model_uuid = juju_model.cos.uuid
  channel    = "2/stable"
}