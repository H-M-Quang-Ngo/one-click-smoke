# COS Configuration K8s Module
#
# Deploys cos-configuration-k8s charm to existing COS model for alert rule forwarding.
#
# Prerequisites:
# - Existing COS deployment with Prometheus and Loki
# - Controller context switched to COS controller (handled by Terragrunt before_hook)
#

# Local Variables - Parse COS Model Path
locals {
  # Parse cos-model format: "controller:owner/model"
  cos_model_parts = split(":", var.cos-model)
  controller      = local.cos_model_parts[0] # cos-controller
  model_full_path = local.cos_model_parts[1] # admin/cos

  # Further parse owner/model
  owner_model_parts = split("/", local.model_full_path)
  model_owner       = local.owner_model_parts[0] # admin
  model_name        = local.owner_model_parts[1] # cos
}

# Data Sources - Get COS Model UUID
data "juju_model" "cos" {
  owner = local.model_owner
  name  = local.model_name
}

resource "juju_application" "cos_config" {
  name       = var.app-name
  model_uuid = data.juju_model.cos.uuid

  charm {
    name    = "cos-configuration-k8s"
    channel = var.charm-channel
  }

  # Git repository configuration for alert rules
  config = {
    git_repo                    = var.git-repo
    git_branch                  = var.git-branch
    prometheus_alert_rules_path = var.prometheus-alert-rules-path
    loki_alert_rules_path       = var.loki-alert-rules-path
  }

  units = 1
}

# Integration with Prometheus
resource "juju_integration" "prometheus" {
  count = var.integrate-prometheus ? 1 : 0

  model_uuid = data.juju_model.cos.uuid

  application {
    name = juju_application.cos_config.name
  }

  application {
    name = "prometheus"
  }

  depends_on = [juju_application.cos_config]
}

# Integration with Loki
resource "juju_integration" "loki" {
  count = var.integrate-loki ? 1 : 0

  model_uuid = data.juju_model.cos.uuid

  application {
    name = juju_application.cos_config.name
  }

  application {
    name = "loki"
  }

  depends_on = [juju_application.cos_config]
}
