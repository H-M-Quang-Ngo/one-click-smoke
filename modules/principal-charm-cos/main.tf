# Principal Charm with COS Integration - Terraform Module
#
# Deploys machine charms with grafana-agent subordinate for COS observability
#
# Supports two deployment paths:
# 1. CharmHub: Native Terraform juju_application resource
# 2. Local .charm: Juju CLI (via before_hook) + terraform import

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
import {
  to = juju_application.principal_imported[0]
  id = "${juju_model.principal.uuid}:${var.app-name}"
}

resource "juju_application" "principal_imported" {
  count = var.charm-source == "local" ? 1 : 0

  name       = var.app-name
  model_uuid = juju_model.principal.uuid

  # Minimal configuration - charm details managed by CLI deployment
  charm {
    name = var.charm-name
  }

  lifecycle {
    # Prevent charm re-deployment while allowing config/resource updates
    ignore_changes = [charm]
  }
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
    juju_application.principal_imported
  ]
}

resource "juju_integration" "cos_agent" {
  count = var.deploy-subordinate ? 1 : 0

  model_uuid = juju_model.principal.uuid

  # Provider: principal charm (provides cos_agent interface)
  application {
    name = try(
      juju_application.principal[0].name,
      juju_application.principal_imported[0].name
    )
    endpoint = "cos_agent"
  }

  # Requirer: grafana-agent subordinate (requires cos_agent interface)
  application {
    name     = juju_application.subordinate[0].name
    endpoint = "cos_agent"
  }

  # Ensure both applications exist before creating relation
  depends_on = [
    juju_application.principal,
    juju_application.principal_imported,
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
