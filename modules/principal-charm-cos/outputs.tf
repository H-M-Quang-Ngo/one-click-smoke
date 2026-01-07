# Terraform Outputs for Principal Charm with COS Integration Module

# Model Outputs
output "model_uuid" {
  value       = juju_model.principal.uuid
  description = "Juju model UUID (required for all integrations in v1.0.0)"
}

output "model_name" {
  value       = juju_model.principal.name
  description = "Juju model name"
}

output "model_id" {
  value       = juju_model.principal.id
  description = "Juju model resource identifier"
}

# Application Outputs
output "app_name" {
  value       = var.charm_source == "charmhub" ? juju_application.principal[0].name : var.app_name
  description = "Application name"
}

output "app_id" {
  # For local charms, construct ID from model UUID and app name
  value       = var.charm_source == "charmhub" ? juju_application.principal[0].id : "${juju_model.principal.uuid}:${var.app_name}"
  description = "Application resource ID"
}

output "charm_name" {
  value       = var.charm_name
  description = "Charm name (CharmHub identifier or local charm name)"
}

output "charm_source" {
  value       = var.charm_source
  description = "Deployment source: 'charmhub' or 'local'"
}

# Application Endpoint Reference for juju_integration Resources
output "app_endpoint_reference" {
  value = {
    model_uuid = juju_model.principal.uuid
    app_name   = var.charm_source == "charmhub" ? juju_application.principal[0].name : var.app_name
  }
  description = "Reference for juju_integration resources (model_uuid + app_name)"
}

# grafana-agent Outputs
output "grafana_agent_deployed" {
  value       = var.enable_cos_integration
  description = "Whether grafana-agent was deployed for COS integration"
}

# Subordinate Charm Integration Outputs
output "cos_integration_id" {
  value = try(
    juju_integration.cos_agent[0].id,
    null
  )
  description = "COS agent relation resource ID (null if not deployed)"
}

output "cos_integration_status" {
  value = try(
    juju_integration.cos_agent[0].id != null ? "active" : "not-deployed",
    "not-deployed"
  )
  description = "COS agent relation status (active = relation established, not-deployed = no subordinate)"
}

# ============================================================================
# COS Cross-Model Integration Outputs (CLI-based)
# ============================================================================
# NOTE: These integrations are created via CLI (`juju integrate`) for cross-controller support.
# The terraform_data resources don't have Juju integration IDs - status is based on resource existence.

output "cos_cross_model_enabled" {
  value       = var.enable_cos_integration
  description = "Whether COS cross-model integration is enabled"
}

output "cos_prometheus_integration_status" {
  value = try(
    terraform_data.cos_prometheus[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Prometheus cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos_loki_integration_status" {
  value = try(
    terraform_data.cos_loki[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Loki cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos_grafana_integration_status" {
  value = try(
    terraform_data.cos_grafana[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Grafana cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos_offer_urls" {
  value = {
    prometheus = var.prometheus_offer_url
    loki       = var.loki_offer_url
    grafana    = var.grafana_offer_url
  }
  description = "COS offer URLs used for cross-model relations"
}
