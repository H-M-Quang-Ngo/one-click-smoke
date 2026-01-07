# Terraform Modules

These modules can be consumed directly in Terraform.

## Module Overview

| Module | Purpose |
|--------|---------|
| `cve-scanner` | Complete `cve-scanner` deployment (`principal-charm-cos` + `cve-scanner-config`) |
| `cos-configuration-k8s` | `cos-configuration-k8s` alert rules deployment |
| `principal-charm-cos` | Generic machine charm deployment with COS integration via `grafana-agent` |
| `cve-scanner-config` | `cve-scanner` configuration |

## Usage

### IMPORTANT: Controller Context

Terraform Juju runs in single Juju controller context. If `cve-scanner` and `cos-configuration-k8s` need to be deployed into different controllers, they must be deployed separately by manually switching controllers between deployments. For example, if there are two Juju controllers: `machine-controller` (for hosting Landscape server charm) and `k8s-controller` (for COS Lite), the deployment steps could be:

1. Switch to `machine-controller` and deploy `cve-scanner` with its terraform module
2. Switch to `k8s-controller` and deploy `cos-configuration-k8s` with its terraform module

### `cve-scanner` Module

Switch to the Juju controller where `cve-scanner` will be deployed. To deploy `cve-scanner` with COS integration to a new model named `cve-scanner`, create this root file:

```hcl
variable "landscape_api_key_value" {
  type      = string
  sensitive = true
}

variable "landscape_api_secret_value" {
  type      = string
  sensitive = true
}

variable "landscape_ca_cert" {
  type    = string
  default = ""
}

module "cve-scanner" {
  source = "git::https://github.com/canonical/one-click-smoke//modules/cve-scanner"

  model_name = "cve-scanner"
  cloud_name = "localhost"

  charm_source = "local"
  charm_path = "./artifacts/cve-scanner.charm"

  snap_resource_path = "./artifacts/cve-scanner.snap"
  landscape_api_uri = "https://landscape.example.com/api/"
  landscape_api_key_value    = var.landscape_api_key_value
  landscape_api_secret_value = var.landscape_api_secret_value
  landscape_ca_cert = var.landscape_ca_cert

  enable_cos_integration = true

  # Supply full offer URLs in the format: controller:owner/model.app:endpoint
  prometheus_offer_url = "cos-controller:admin/cos.prometheus-receive-remote-write"
  loki_offer_url = "cos-controller:admin/cos.loki-logging"
  grafana_offer_url = "cos-controller:admin/cos.grafana-dashboards"
}

```

Then deploy with terraform:

```bash
export TF_VAR_landscape_api_key_value=<landscape_api_key>
export TF_VAR_landscape_api_secret_value=<landscape_api_secret>
export TF_VAR_landscape_ca_cert=<landscape_ca_cert> # In PEM format, if landscape uses self-signed certificate
terraform init
terraform apply
```

### `cos-configuration-k8s` Module

Switch to the Juju controller where COS Lite is deployed. To deploy `cos-configuration-k8s` into the existing Juju model hosting COS Lite, create this root file:

```hcl
module "cos-config" {
  source = "git::https://github.com/canonical/one-click-smoke//modules/cos-configuration-k8s"

  cos_model = "k8s-controller:admin/cos" # Supply full model with format: controller:owner/model
  git_repo = "https://github.com/canonical/smoke-alerts"
  prometheus_alert_rules_path = "rules/prod/prometheus/"
  loki_alert_rules_path       = "rules/prod/loki/"
}
```
Then deploy with terraform:

```bash
terraform init
terraform apply
```

