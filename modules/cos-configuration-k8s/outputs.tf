# COS Configuration K8s Module Outputs

# Application Information
output "app_name" {
  description = "Name of the deployed cos-configuration-k8s application"
  value       = juju_application.cos_config.name
}

output "app-id" {
  description = "Full Juju application ID (model_uuid:app_name)"
  value       = juju_application.cos_config.id
}

output "model-name" {
  description = "COS model name where cos-configuration-k8s is deployed"
  value       = local.model_full_path
}

output "model-uuid" {
  description = "COS model UUID"
  value       = data.juju_model.cos.uuid
}

# Git Configuration
output "git-repo" {
  description = "Git repository URL for alert rules"
  value       = var.git_repo
}

output "git-branch" {
  description = "Git branch being used"
  value       = var.git_branch
}

# Integration Status
output "prometheus-integration-status" {
  description = "Prometheus integration status"
  value       = var.integrate_prometheus ? (length(juju_integration.prometheus) > 0 ? "active" : "pending") : "disabled"
}

output "prometheus-integration-id" {
  description = "Prometheus integration ID (if enabled)"
  value       = var.integrate_prometheus && length(juju_integration.prometheus) > 0 ? juju_integration.prometheus[0].id : null
}

output "loki-integration-status" {
  description = "Loki integration status"
  value       = var.integrate_loki ? (length(juju_integration.loki) > 0 ? "active" : "pending") : "disabled"
}

output "loki-integration-id" {
  description = "Loki integration ID (if enabled)"
  value       = var.integrate_loki && length(juju_integration.loki) > 0 ? juju_integration.loki[0].id : null
}
