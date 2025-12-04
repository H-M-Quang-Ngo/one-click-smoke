# Smoke Detector Deployment - Root Terragrunt Configuration
#
# This file provides common configuration inherited by all component terragrunt.hcl files.
# Components include this via: include "root" { path = find_in_parent_folders("smoke-root.hcl") }
#
# Architecture:
# - Root config (this file): Remote state, provider generation, common inputs
# - Component config (environments/*/component/terragrunt.hcl): Component-specific settings
#
# Components directly include this file

locals {
  # Project root directory
  project_root = get_repo_root()
}

# Remote State Configuration
# Using local backend for single-user development
# Later could migrate to S3 backend
remote_state {
  backend = "local"

  config = {
    path = "${get_parent_terragrunt_dir()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
}

# Generate Terraform Provider Configuration
# Automatically creates provider.tf in each module
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
# Provider requirements (source, version) are declared in versions.tf
provider "juju" {}
EOF
}

# Common inputs available to all child modules
inputs = {
  # Project metadata
  project_name = "smoke-detector"

  # Tags for resources
  tags = {
    project    = "smoke-detector"
    managed_by = "terragrunt"
  }
}
