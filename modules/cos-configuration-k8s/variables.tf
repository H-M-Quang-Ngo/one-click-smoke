# COS Configuration K8s Module Variables
#
# This module deploys cos-configuration-k8s charm to an existing COS model
# for alert rule forwarding from a Git repository.
#

# COS Model Configuration
variable "cos_model" {
  description = "COS model in format: controller:owner/model (e.g., cos-controller:admin/cos)"
  type        = string

  validation {
    condition     = can(regex("^[^:]+:[^/]+/[^.]+$", var.cos_model))
    error_message = "cos-model must be in format 'controller:owner/model' (e.g., 'cos-controller:admin/cos')"
  }
}

# Git Repository Configuration
variable "git_repo" {
  description = "Git repository URL containing alert rules (e.g., https://github.com/canonical/smoke-alerts)"
  type        = string
}

variable "git_branch" {
  description = "Git branch to use (e.g., main, master)"
  type        = string
  default     = "main"
}

variable "prometheus_alert_rules_path" {
  description = "Path to Prometheus alert rules in the Git repo (e.g., rules/prod/prometheus/)"
  type        = string
}

variable "loki_alert_rules_path" {
  description = "Path to Loki alert rules in the Git repo (e.g., rules/prod/loki/)"
  type        = string
}

# Application Configuration
variable "app_name" {
  description = "Application name for cos-configuration-k8s charm"
  type        = string
  default     = "cos-config"
}

variable "charm_channel" {
  description = "CharmHub channel for cos-configuration-k8s (e.g., latest/stable, latest/edge)"
  type        = string
  default     = "1/stable"
}

# Integration Configuration
variable "integrate_prometheus" {
  description = "Enable integration with Prometheus"
  type        = bool
  default     = true
}

variable "integrate_loki" {
  description = "Enable integration with Loki"
  type        = bool
  default     = true
}
