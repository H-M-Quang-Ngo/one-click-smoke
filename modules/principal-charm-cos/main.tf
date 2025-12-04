# Principal Charm with COS Integration - Terraform Module
#
# Deploys machine charms with grafana-agent subordinate for COS observability
#
# Supports two deployment paths:
# 1. CharmHub: Native Terraform juju_application resource
# 2. Local .charm: Juju CLI (via terraform_data provisioner)
#
# NOTE: Juju Terraform provider does NOT support local charms.
# For local charms, we deploy via CLI and reference by name (not as a resource).

locals {
  # Ensure exactly one deployment path is active
  charmhub_count = var.charm-source == "charmhub" ? 1 : 0
  local_count    = var.charm-source == "local" ? 1 : 0

  # Validate mutual exclusivity
  _ = local.charmhub_count + local.local_count == 1 ? null : tobool("FATAL: charm-source must be either 'charmhub' or 'local', not both")
}

# Juju model resource
resource "juju_model" "principal" {
  name = var.model-name

  cloud {
    name   = var.cloud-name
    region = var.cloud-region
  }
}

# Charm Deployment (CharmHub Path)
resource "juju_application" "principal" {
  count = var.charm-source == "charmhub" ? 1 : 0

  name       = var.app-name
  model_uuid = juju_model.principal.uuid
  units      = var.units

  charm {
    name    = var.charm-name
    channel = var.charm-channel
    base    = var.base
  }

  constraints = var.constraints
}


# Charm Deployment (Local .charm Path)
# Deploy via CLI - provider cannot manage local charms, so we just deploy and reference by name
resource "terraform_data" "local_charm_deploy_and_import" {
  count = var.charm-source == "local" ? 1 : 0

  # Deploy charm via Juju CLI after model is created
  provisioner "local-exec" {
    command     = "${var.repo-root}/scripts/deploy-local-charm.sh '${juju_model.principal.name}' '${var.charm-path}' '${var.app-name}' '${var.units}' '${var.base}'"
    working_dir = path.root
  }

  # Ensure model exists before deploying
  depends_on = [juju_model.principal]
}

# Subordinate Charm Deployment (grafana-agent)
resource "juju_application" "subordinate" {
  count = var.deploy-subordinate ? 1 : 0

  name       = var.subordinate-name
  model_uuid = juju_model.principal.uuid

  charm {
    name    = var.subordinate-name
    channel = var.subordinate-charm-channel
    base    = var.base
  }

  # Ensure principal app exists before deploying subordinate
  depends_on = [
    juju_application.principal,
    terraform_data.local_charm_deploy_and_import
  ]
}

resource "juju_integration" "cos_agent" {
  count = var.deploy-subordinate ? 1 : 0

  model_uuid = juju_model.principal.uuid

  # Provider: principal charm (provides cos-agent relation)
  application {
    name     = var.charm-source == "charmhub" ? juju_application.principal[0].name : var.app-name
    endpoint = "cos-agent"
  }

  # Requirer: grafana-agent subordinate (requires cos-agent relation)
  application {
    name     = juju_application.subordinate[0].name
    endpoint = "cos-agent"
  }

  # Ensure both applications exist before creating relation
  depends_on = [
    juju_application.principal,
    terraform_data.local_charm_deploy_and_import,
    juju_application.subordinate
  ]
}

# COS Cross-Model Relations
## CMR: grafana-agent -> Prometheus
resource "juju_integration" "cos_prometheus" {
  count      = var.enable-cos-integration && var.deploy-subordinate && var.prometheus-offer-url != "" ? 1 : 0
  model_uuid = juju_model.principal.uuid
  application {
    name     = juju_application.subordinate[0].name
    endpoint = "send-remote-write"
  }
  application {
    offer_url = var.prometheus-offer-url
  }
  depends_on = [
    juju_application.subordinate,
    juju_integration.cos_agent
  ]
}

## CMR: grafana-agent -> Loki
resource "juju_integration" "cos_loki" {
  count      = var.enable-cos-integration && var.deploy-subordinate && var.loki-offer-url != "" ? 1 : 0
  model_uuid = juju_model.principal.uuid
  application {
    name     = juju_application.subordinate[0].name
    endpoint = "logging-consumer"
  }
  application {
    offer_url = var.loki-offer-url
  }
  depends_on = [
    juju_application.subordinate,
    juju_integration.cos_agent
  ]
}

## CMR: grafana-agent -> Grafana
resource "juju_integration" "cos_grafana" {
  count      = var.enable-cos-integration && var.deploy-subordinate && var.grafana-offer-url != "" ? 1 : 0
  model_uuid = juju_model.principal.uuid
  application {
    name     = juju_application.subordinate[0].name
    endpoint = "grafana-dashboards-provider"
  }
  application {
    offer_url = var.grafana-offer-url
  }

  depends_on = [
    juju_application.subordinate,
    juju_integration.cos_agent
  ]
}
