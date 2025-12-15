# Terraform Variables - Default Environment
#
# This file contains all environment-specific variables
#
locals {
  environment = "default"

  # ============================================================================
  # CVE-Scanner Configuration
  # ============================================================================
  controller_name = "my-controller"
  model_name      = "cve-scanner-model"
  cloud_name      = "localhost"
  cloud_region    = "localhost"

  # cve-scanner charm deployment configuration
  charm_source = "local"

  # Local charm file path (only used if charm_source = "local")
  charm_path = "/path/to/cve-scanner.charm"

  # Local snap resource path for resource attachment
  snap_resource_path = "/path/to/cve-scanner.snap"

  # CharmHub configuration (only used if charm_source = "charmhub")
  charm_name    = "cve-scanner"
  charm_channel = "latest/stable"

  # Application configuration
  app_name = "cve-scanner"
  units    = 1
  base     = "ubuntu@24.04"

  # Deployment constraints (optional)
  constraints = "" # Example: "mem=4G cores=2"

  # ============================================================================
  # Stage 2: CVE-Scanner Landscape Configuration
  # ============================================================================

  # Landscape API endpoint (REQUIRED for CVE-Scanner functionality)
  landscape_api_uri = "https://landscape.canonical.com/api/"

  # Terraform-managed secrets for Landscape credentials (REQUIRED)
  manage_secrets             = true
  landscape_api_key_value    = "CHANGEME-API-KEY"
  landscape_api_secret_value = "CHANGEME-API-SECRET"

  # IMPORTANT: Use environment variables instead:
  #   export TF_VAR_landscape_api_key_value="actual-key"
  #   export TF_VAR_landscape_api_secret_value="actual-secret"

  # CA certificate for self-signed Landscape servers (OPTIONAL)
  # Provide path to CA cert file - content will be read and supplied to charm
  landscape_ca_cert_file = "" # Example: "/path/to/ca-cert.pem"

  # ============================================================================
  # COS Integration
  # ============================================================================
  # When enabled: deploys grafana-agent and creates cross-model relations to COS
  enable_cos_integration = true
  grafana_agent_channel  = "latest/stable"

  # COS offer URLs (format: controller:owner/model.app:endpoint)
  prometheus_offer_url = "cos-controller:admin/cos.prometheus-receive-remote-write"
  loki_offer_url       = "cos-controller:admin/cos.loki-logging"
  grafana_offer_url    = "cos-controller:admin/cos.grafana-dashboards"

  # ============================================================================
  # COS Configuration K8s Charm (Alert Rule Forwarding)
  # ============================================================================
  # Independent component that deploys to COS model
  # Pulls alert rules from Git repository and forwards to Prometheus/Loki

  # COS model location (format: controller:owner/model)
  cos_model = "cos-controller:admin/cos"

  # Git repository configuration
  cos_config_git_repo                    = "https://github.com/canonical/smoke-alerts"
  cos_config_git_branch                  = "main"
  cos_config_prometheus_alert_rules_path = "rules/prod/prometheus/"
  cos_config_loki_alert_rules_path       = "rules/prod/loki/"

  # Application settings
  cos_config_app_name      = "cos-config"
  cos_config_charm_channel = "1/stable"

  # Integration toggles
  cos_config_integrate_prometheus = true
  cos_config_integrate_loki       = true
}

# ============================================================================
# Security Notes
# ============================================================================

# IMPORTANT: Configuration file pattern
# - This is a TEMPLATE file (tracked in git) with placeholder values
# - Copy to 'environment-config.hcl' (ignored by git) and fill in actual values
# - DON'T commit actual secrets to version control
#
# Setup:
#   cp environment-config.template.hcl environment-config.hcl
#   # Edit environment-config.hcl with actual values
#
# Recommended: Use environment variables for secrets (overrides file values)
#   export TF_VAR_landscape_api_key_value="actual-key"
#   export TF_VAR_landscape_api_secret_value="actual-secret"
