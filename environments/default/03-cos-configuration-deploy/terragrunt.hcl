# Stage 3: COS Configuration K8s Charm
#
# Deploys cos-configuration-k8s charm to existing COS model for alert rule forwarding
#
# This stage is independent from cve-scanner (Stages 1 & 2)
#

terraform {
  source = "../../../modules/cos-configuration-k8s"

  # Switch to COS controller before Terraform operations
  before_hook "switch_to_cos_controller" {
    commands = ["apply", "destroy"]
    execute  = ["juju", "switch", local.cos_model]
  }

  # Wait for cos-configuration-k8s to be active after deployment
  after_hook "wait_for_active" {
    commands = ["apply"]
    execute  = ["${get_repo_root()}/scripts/wait-for-application.sh", local.model_path, local.app_name, "status==\"active\""]
  }
}

include "root" {
  path = find_in_parent_folders("smoke-root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("environment-config.hcl"))

  # COS Configuration variables
  cos_model                   = local.env_vars.locals.cos_model
  git_repo                    = local.env_vars.locals.cos_config_git_repo
  git_branch                  = local.env_vars.locals.cos_config_git_branch
  prometheus_alert_rules_path = local.env_vars.locals.cos_config_prometheus_alert_rules_path
  loki_alert_rules_path       = local.env_vars.locals.cos_config_loki_alert_rules_path
  app_name                    = local.env_vars.locals.cos_config_app_name
  charm_channel               = local.env_vars.locals.cos_config_charm_channel
  integrate_prometheus        = local.env_vars.locals.cos_config_integrate_prometheus
  integrate_loki              = local.env_vars.locals.cos_config_integrate_loki

  # Parse model_path for wait_for_active hook
  # Example: "cos-controller:admin/cos" -> "admin/cos"
  model_path = split(":", local.cos_model)[1]
}

inputs = {
  # COS model configuration
  cos-model = local.cos_model

  # Git repository configuration
  git-repo                    = local.git_repo
  git-branch                  = local.git_branch
  prometheus-alert-rules-path = local.prometheus_alert_rules_path
  loki-alert-rules-path       = local.loki_alert_rules_path

  # Application settings
  app-name      = local.app_name
  charm-channel = local.charm_channel

  # Integration toggles
  integrate-prometheus = local.integrate_prometheus
  integrate-loki       = local.integrate_loki
}
