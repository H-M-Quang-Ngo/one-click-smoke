# COS Configuration K8s Module Variables
#
# This module deploys cos-configuration-k8s charm to an existing COS model
# for alert rule forwarding from a Git repository.
#

# COS Model Configuration
variable "cos-model" {
  description = "COS model in format: controller:owner/model (e.g., cos-controller:admin/cos)"
  type        = string

  validation {
    condition     = can(regex("^[^:]+:[^/]+/[^.]+$", var.cos-model))
    error_message = "cos-model must be in format 'controller:owner/model' (e.g., 'cos-controller:admin/cos')"
  }
}

# Git Repository Configuration
variable "git-repo" {
  description = "Git repository URL containing alert rules (e.g., https://github.com/canonical/smoke-alerts)"
  type        = string
}

variable "git-branch" {
  description = "Git branch to use (e.g., main, master)"
  type        = string
  default     = "main"
}

variable "prometheus-alert-rules-path" {
  description = "Path to Prometheus alert rules in the Git repo (e.g., rules/prod/prometheus/)"
  type        = string
}

variable "loki-alert-rules-path" {
  description = "Path to Loki alert rules in the Git repo (e.g., rules/prod/loki/)"
  type        = string
}

# Application Configuration
variable "app-name" {
  description = "Application name for cos-configuration-k8s charm"
  type        = string
  default     = "cos-config"
}

variable "charm-channel" {
  description = "CharmHub channel for cos-configuration-k8s (e.g., latest/stable, latest/edge)"
  type        = string
  default     = "latest/stable"
}

# Integration Configuration
variable "integrate-prometheus" {
  description = "Enable integration with Prometheus"
  type        = bool
  default     = true
}

variable "integrate-loki" {
  description = "Enable integration with Loki"
  type        = bool
  default     = true
}
