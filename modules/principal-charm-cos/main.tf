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

# grafana-agent Deployment (only when COS integration is enabled)
resource "juju_application" "grafana_agent" {
  count = var.enable-cos-integration ? 1 : 0

  name       = "grafana-agent"
  model_uuid = juju_model.principal.uuid

  charm {
    name    = "grafana-agent"
    channel = var.grafana-agent-channel
    base    = var.base
  }

  # Ensure principal app exists before deploying grafana-agent
  depends_on = [
    juju_application.principal,
    terraform_data.local_charm_deploy_and_import
  ]
}

# cos-agent relation: principal charm <-> grafana-agent
resource "juju_integration" "cos_agent" {
  count = var.enable-cos-integration ? 1 : 0

  model_uuid = juju_model.principal.uuid

  # Provider: principal charm (provides cos-agent relation)
  application {
    name     = var.charm-source == "charmhub" ? juju_application.principal[0].name : var.app-name
    endpoint = "cos-agent"
  }

  # Requirer: grafana-agent subordinate (requires cos-agent relation)
  application {
    name     = "grafana-agent"
    endpoint = "cos-agent"
  }

  # Ensure both applications exist before creating relation
  depends_on = [
    juju_application.principal,
    terraform_data.local_charm_deploy_and_import,
    juju_application.grafana_agent
  ]
}

# ============================================================================
# COS Cross-Model Relations (CLI-based for cross-controller CMR)
# ============================================================================
# NOTE: Juju Terraform provider only talks to one controller at a time.
# However, COS could be hosted in a different controller than the deployed charm.
# Therefore, for cross-controller CMR, a workaround is to use CLI:
# `juju integrate -m <model> <app>:<endpoint> <offer-url>`

## CMR: grafana-agent -> Prometheus
resource "terraform_data" "cos_prometheus" {
  count = var.enable-cos-integration && var.prometheus-offer-url != "" ? 1 : 0

  provisioner "local-exec" {
    command = "juju integrate -m '${juju_model.principal.name}' 'grafana-agent:send-remote-write' '${var.prometheus-offer-url}'"
  }

  depends_on = [
    juju_application.grafana_agent,
    juju_integration.cos_agent
  ]
}

## CMR: grafana-agent -> Loki
resource "terraform_data" "cos_loki" {
  count = var.enable-cos-integration && var.loki-offer-url != "" ? 1 : 0

  provisioner "local-exec" {
    command = "juju integrate -m '${juju_model.principal.name}' 'grafana-agent:logging-consumer' '${var.loki-offer-url}'"
  }

  depends_on = [
    juju_application.grafana_agent,
    juju_integration.cos_agent
  ]
}

## CMR: grafana-agent -> Grafana
resource "terraform_data" "cos_grafana" {
  count = var.enable-cos-integration && var.grafana-offer-url != "" ? 1 : 0

  provisioner "local-exec" {
    command = "juju integrate -m '${juju_model.principal.name}' 'grafana-agent:grafana-dashboards-provider' '${var.grafana-offer-url}'"
  }

  depends_on = [
    juju_application.grafana_agent,
    juju_integration.cos_agent
  ]
}
