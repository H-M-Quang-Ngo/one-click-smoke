# Terraform Outputs for Principal Charm with COS Integration Module

# Model Outputs
output "model-uuid" {
  value       = juju_model.principal.uuid
  description = "Juju model UUID (required for all integrations in v1.0.0)"
}

output "model-name" {
  value       = juju_model.principal.name
  description = "Juju model name"
}

output "model-id" {
  value       = juju_model.principal.id
  description = "Juju model resource identifier"
}

# Application Outputs
output "app-name" {
  value       = var.charm-source == "charmhub" ? juju_application.principal[0].name : var.app-name
  description = "Application name"
}

output "app-id" {
  # For local charms, construct ID from model UUID and app name
  value       = var.charm-source == "charmhub" ? juju_application.principal[0].id : "${juju_model.principal.uuid}:${var.app-name}"
  description = "Application resource ID"
}

output "charm-name" {
  value       = var.charm-name
  description = "Charm name (CharmHub identifier or local charm name)"
}

output "charm-source" {
  value       = var.charm-source
  description = "Deployment source: 'charmhub' or 'local'"
}

# Application Endpoint Reference for juju_integration Resources
output "app-endpoint-reference" {
  value = {
    model_uuid = juju_model.principal.uuid
    app_name   = var.charm-source == "charmhub" ? juju_application.principal[0].name : var.app-name
  }
  description = "Reference for juju_integration resources (model_uuid + app_name)"
}

# grafana-agent Outputs
output "grafana-agent-deployed" {
  value       = var.enable-cos-integration
  description = "Whether grafana-agent was deployed for COS integration"
}

# Subordinate Charm Integration Outputs
output "cos-integration-id" {
  value = try(
    juju_integration.cos_agent[0].id,
    null
  )
  description = "COS agent relation resource ID (null if not deployed)"
}

output "cos-integration-status" {
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

output "cos-cross-model-enabled" {
  value       = var.enable-cos-integration
  description = "Whether COS cross-model integration is enabled"
}

output "cos-prometheus-integration-status" {
  value = try(
    terraform_data.cos_prometheus[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Prometheus cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos-loki-integration-status" {
  value = try(
    terraform_data.cos_loki[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Loki cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos-grafana-integration-status" {
  value = try(
    terraform_data.cos_grafana[0].id != null ? "created-via-cli" : "not-deployed",
    "not-deployed"
  )
  description = "Grafana cross-model relation status (created-via-cli = CLI integration ran)"
}

output "cos-offer-urls" {
  value = {
    prometheus = var.prometheus-offer-url
    loki       = var.loki-offer-url
    grafana    = var.grafana-offer-url
  }
  description = "COS offer URLs used for cross-model relations"
}
