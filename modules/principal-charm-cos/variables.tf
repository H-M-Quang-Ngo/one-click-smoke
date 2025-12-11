# Terraform Variables for Principal Charm with COS Integration via Grafana-Agent
#
# This module supports deploying machine charms from CharmHub or local .charm files
# with grafana-agent subordinate integration for COS integration.

# Repository Root Path
variable "repo-root" {
  description = "Absolute path to repository root (for resolving script paths)"
  type        = string
}

# Model Variables
variable "model-name" {
  description = "Juju model name for deploying the principal charm"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.model-name))
    error_message = "Model name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "cloud-name" {
  description = "Juju cloud name (e.g., localhost, aws, azure, gcp)"
  type        = string
  default     = "localhost"
}

variable "cloud-region" {
  description = "Cloud region for model deployment"
  type        = string
  default     = "localhost"
}

# Charm Deployment Variables
variable "charm-source" {
  description = "Charm deployment source: 'charmhub' (native Terraform) or 'local' (CLI + import)"
  type        = string

  validation {
    condition     = contains(["charmhub", "local"], var.charm-source)
    error_message = "charm-source must be either 'charmhub' or 'local'"
  }
}

variable "charm-path" {
  description = "Path to local .charm file (required if charm-source='local', ignored otherwise)"
  type        = string
  default     = null
}

variable "charm-name" {
  description = "Charm name (CharmHub identifier or local charm name)"
  type        = string
}

variable "charm-channel" {
  description = "CharmHub channel (e.g., latest/stable, latest/edge)"
  type        = string
  default     = "latest/stable"
}

variable "app-name" {
  description = "Juju application name for the principal charm"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.app-name))
    error_message = "Application name must contain only lowercase letters, numbers, and hyphens"
  }
}

variable "units" {
  description = "Number of application units (for machine charms)"
  type        = number
  default     = 1

  validation {
    condition     = var.units >= 1
    error_message = "Must deploy at least 1 unit"
  }
}

variable "base" {
  description = "Base OS version (e.g., 'ubuntu@22.04', 'ubuntu@24.04')"
  type        = string

  validation {
    condition     = can(regex("^ubuntu@[0-9]{2}\\.[0-9]{2}$", var.base))
    error_message = "Base must be in format 'ubuntu@XX.YY' (e.g., 'ubuntu@22.04')"
  }
}

# Machine Deployment Constraints
variable "constraints" {
  description = "Juju constraints (e.g., 'mem=4G cores=2')"
  type        = string
  default     = null
}

# COS Integration Variables
# grafana-agent is only deployed when COS integration is enabled.
variable "enable-cos-integration" {
  description = "Enable COS integration: deploys grafana-agent and creates cross-model relations to COS"
  type        = bool
  default     = true
}

variable "grafana-agent-channel" {
  description = "CharmHub channel for grafana-agent (e.g., latest/stable, latest/edge)"
  type        = string
  default     = "latest/stable"
}

variable "prometheus-offer-url" {
  description = "Prometheus offer URL for metrics collection (format: controller:owner/model.app:endpoint). Example: cos-controller:admin/cos.prometheus:metrics-endpoint"
  type        = string
  default     = ""
}

variable "loki-offer-url" {
  description = "Loki offer URL for logs forwarding (format: controller:owner/model.app:endpoint). Example: cos-controller:admin/cos.loki:logging"
  type        = string
  default     = ""
}

variable "grafana-offer-url" {
  description = "Grafana offer URL for dashboard integration (format: controller:owner/model.app:endpoint). Example: cos-controller:admin/cos.grafana:grafana-dashboard"
  type        = string
  default     = ""
}
