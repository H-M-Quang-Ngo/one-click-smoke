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
  value = try(
    juju_application.principal[0].name,
    try(
      juju_application.principal_imported[0].name,
      var.app-name
    )
  )
  description = "Application name"
}

output "app-id" {
  value = try(
    juju_application.principal[0].id,
    try(
      juju_application.principal_imported[0].id,
      null
    )
  )
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
    app_name = try(
      juju_application.principal[0].name,
      try(
        juju_application.principal_imported[0].name,
        var.app-name
      )
    )
  }
  description = "Reference for juju_integration resources (model_uuid + app_name)"
}

# Subordinate Charm Outputs
output "subordinate-name" {
  value = try(
    juju_application.subordinate[0].name,
    null
  )
  description = "Subordinate charm application name (null if not deployed)"
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
# COS Cross-Model Integration Outputs
# ============================================================================

output "cos-cross-model-enabled" {
  value       = var.enable-cos-integration
  description = "Whether COS cross-model integration is enabled"
}

output "cos-prometheus-integration-id" {
  value = try(
    juju_integration.cos_prometheus[0].id,
    null
  )
  description = "Prometheus cross-model relation resource ID (null if not deployed)"
}

output "cos-prometheus-integration-status" {
  value = try(
    juju_integration.cos_prometheus[0].id != null ? "active" : "not-deployed",
    "not-deployed"
  )
  description = "Prometheus cross-model relation status"
}

output "cos-loki-integration-id" {
  value = try(
    juju_integration.cos_loki[0].id,
    null
  )
  description = "Loki cross-model relation resource ID (null if not deployed)"
}

output "cos-loki-integration-status" {
  value = try(
    juju_integration.cos_loki[0].id != null ? "active" : "not-deployed",
    "not-deployed"
  )
  description = "Loki cross-model relation status"
}

output "cos-grafana-integration-id" {
  value = try(
    juju_integration.cos_grafana[0].id,
    null
  )
  description = "Grafana cross-model relation resource ID (null if not deployed)"
}

output "cos-grafana-integration-status" {
  value = try(
    juju_integration.cos_grafana[0].id != null ? "active" : "not-deployed",
    "not-deployed"
  )
  description = "Grafana cross-model relation status"
}

output "cos-offer-urls" {
  value = {
    prometheus = var.prometheus-offer-url
    loki       = var.loki-offer-url
    grafana    = var.grafana-offer-url
  }
  description = "COS offer URLs used for cross-model relations"
}
