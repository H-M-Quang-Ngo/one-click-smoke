# Stage 1 - CVE Scanner and Grafana-Agent Deployment
#
# - Deploy cve-scanner charm
# - Deploy grafana-agent and relate to cve-scanner
# - Relate grafana-agent to COS components
#

terraform {
  source = "../../../modules/principal-charm-cos"

  # Wait for principal to be deployed (active or blocked)
  after_hook "wait_for_principal_deployed" {
    commands = ["apply"]
    execute  = ["${get_repo_root()}/scripts/wait-for-application.sh", local.model_name, local.app_name, "status==\"active\" || status==\"blocked\""]
  }

  # Wait for subordinate to be active
  after_hook "wait_for_subordinate" {
    commands = ["apply"]
    execute  = ["${get_repo_root()}/scripts/wait-for-application.sh", local.model_name, local.subordinate_name, "status==\"active\""]
  }
}

include "root" {
  path = find_in_parent_folders("smoke-root.hcl")
}

locals {
  # Read from parent directory
  env_vars = read_terragrunt_config(find_in_parent_folders("environment-config.hcl"))

  # Get absolute repository root path
  repo_root_absolute = get_repo_root()

  # Extract common variables
  model_name   = local.env_vars.locals.model_name
  cloud_name   = local.env_vars.locals.cloud_name
  cloud_region = local.env_vars.locals.cloud_region

  # Charm deployment configuration
  charm_source  = local.env_vars.locals.charm_source
  charm_path    = try(local.env_vars.locals.charm_path, "")
  charm_name    = local.env_vars.locals.charm_name
  charm_channel = try(local.env_vars.locals.charm_channel, "latest/stable")
  app_name      = local.env_vars.locals.app_name
  units         = local.env_vars.locals.units
  base          = local.env_vars.locals.base
  constraints   = try(local.env_vars.locals.constraints, "")

  # Subordinate configuration
  deploy_subordinate         = try(local.env_vars.locals.deploy_subordinate, true)
  subordinate_name           = local.env_vars.locals.subordinate_name
  subordinate_charm_channel  = local.env_vars.locals.subordinate_charm_channel

  # COS cross-model integration
  enable_cos_integration = try(local.env_vars.locals.enable_cos_integration, true)
  prometheus_offer_url   = local.env_vars.locals.prometheus_offer_url
  loki_offer_url         = local.env_vars.locals.loki_offer_url
  grafana_offer_url      = local.env_vars.locals.grafana_offer_url
}

inputs = {
  # Repository root for script resolution (absolute path)
  repo-root = local.repo_root_absolute

  # Model configuration
  model-name   = local.model_name
  cloud-name   = local.cloud_name
  cloud-region = local.cloud_region

  # Principal charm deployment
  charm-source   = local.charm_source
  charm-path     = local.charm_path   # Only used if charm-source = "local"
  charm-name     = local.charm_name
  charm-channel  = local.charm_channel
  app-name       = local.app_name
  units          = local.units
  base           = local.base
  constraints    = local.constraints

  # Subordinate charm (grafana-agent)
  deploy-subordinate        = local.deploy_subordinate
  subordinate-name          = local.subordinate_name
  subordinate-charm-channel = local.subordinate_charm_channel

  # COS cross-model relations
  enable-cos-integration = local.enable_cos_integration
  prometheus-offer-url   = local.prometheus_offer_url
  loki-offer-url         = local.loki_offer_url
  grafana-offer-url      = local.grafana_offer_url
}
