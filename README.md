# Smoke Detector One-Click Deployment

Automated deployment tool for Smoke Detector using Terragrunt + Terraform + Bash.

## Overview

This project provides Infrastructure as Code (IaC) for deploying and managing Smoke Detector components:

- **cve-scanner** - Machine charm for CVE scanning packages in nodes managed by a Landscape Server
- **cos-configuration-k8s** - K8s charm for COS alert rule forwarding

Both components integrate with Canonical Observability Stack (COS) for monitoring and alerting.

## Architecture

- **Terragrunt** - Multi-environment orchestration and DRY configuration
- **Terraform** - Declarative infrastructure provisioning via Juju provider
- **Bash Hooks** - Support Terragrunt for local `.charm` file deployment and other custom hooks
- **Juju** - Application modeling and lifecycle management

## Prerequisites

- Existing Juju controller (bootstrapped)
- Existing Landscape Server (for cve-scanner)
- Juju cloud that can deploy machines (LXD, MAAS, etc.) - recommended to be the one hosting [Landscape charm](https://github.com/canonical/landscape-charm)
- Existing COS deployment with exposed offers

## What will be Deployed?
- **cve-scanner**:
  - A new Juju model will be created with `cve-scanner` principal machine charm deployed
  - `grafana-agent` installed, connected to `cve-scanner` and integrated with existing COS via provided offers
  - `cve-scanner` configured with provided Landscape credentials for retrieving package data from managed nodes

- **cos-configuration-k8s**:
  - `cos-configuration-k8s` charm deployed into the existing Juju model that hosting COS
  - Configured to sync alert rules from [Smoke-Alerts](https://github.com/canonical/smoke-alerts) repository
  - Integrate with Prometheus and Loki for alert rule forwarding

## Start

### 1. Bootstrap Environment

Check/install required tools (Terraform, Terragrunt, Juju CLI):

```bash
./scripts/bootstrap.sh
```

### 2. Configure Environment
Each environment is located in `./environments/<env-name>/`. Use the provided template to create your own environment configuration. In this example, we use `default` environment.

In the environment directory, copy and edit the environment configuration:

```bash
cd ./environments/default
cp environment-config.example.hcl environment-config.hcl
vim environment-config.hcl
```

### 3. Deploy Components

**IMPORTANT:** Terraform Juju provider does not support controller switching and only allows one controller at a time, but `cve-scanner` and `cos-configuration-k8s` are independent components that can be deployed into different controllers and in any order. Therefore, commands like `terragrunt apply --all` for a one-click deployment from the environment root **cannot** be run to avoid controller race conditions. Instead, we have two options as below. Other operations can be done normally with Terraform/Terragrunt commands in each component directory.

#### 3.1. Manual Deployment:

From the environment directory (for example, `./environments/default/`), either or both the `cve-scanner` and `cos-configuration-k8s` can be deployed with the following commands:

```bash
cd ./environments/default

# CVE Scanner Deployment - 2 stages
## Stage 1: Deploy cve-scanner charm + grafana-agent + COS integration
terragrunt --working-dir 01-principal-deploy apply --auto-approve

## Stage 2: Configure cve-scanner (Landscape credentials, snap resource)
terragrunt --working-dir 02-cve-scanner-specific apply --auto-approve

# COS Configuration Deployment
## Deploy cos-configuration-k8s charm (on COS model) and make integration
terragrunt --working-dir 03-cos-configuration-deploy apply --auto-approve
```

#### 3.2. One-Click Deployment Script:
Alternatively, use the provided [one-click deploy script](one-click-deploy) at the project root as a wrapper to deploy either or both components in one command:

```bash
# Deploy both cve-scanner and cos-configuration-k8s from ./environments/default environment
./one-click-deploy --env default --cve-scanner --cos-config

# Deploy only cve-scanner
./one-click-deploy --env default --cve-scanner

# Deploy only cos-configuration-k8s
./one-click-deploy --env default --cos-config

# Plan changes before applying (preview mode)
./one-click-deploy --env default --cve-scanner --plan

# Destroy infrastructure
./one-click-deploy --env default --cve-scanner --destroy
```

See script help for all options:

```bash
./one-click-deploy --help
```

## Directory Structure

```
one-click-smoke/
├── modules/              # Reusable Terraform modules
│   ├── principal-charm-cos/                # Machine charm + grafana-agent + COS integration
│   ├── cve-scanner/                        # Setup for CVE Scanner charm (required configs, resources)
│   └── cos-configuration-k8s/              # COS configuration charm
├── environments/         # Environment-specific setup
│   └── default/
│       ├── environment-config.hcl          # Environment configurations (not committed, taken from template)
│       ├── environment-config.template.hcl     # Template for environment configuration
│       ├── 01-principal-deploy/            # Deploy machine charm and connect to COS (via grafana-agent)
│       │   └── terragrunt.hcl
│       └── 02-cve-scanner-specific/        # Configure CVE Scanner charm
│       │   └── terragrunt.hcl
│       └── 03-cos-configuration-deploy/    # Deploy COS configuration charm and connect to COS
│           └── terragrunt.hcl
├── scripts/              # Helper scripts
│   ├── bootstrap.sh                  # Tool check/installation
│   ├── deploy-local-charm.sh         # Local charm deployment
│   ├── wait-for-application.sh       # Wait for Juju app ready
│   └── cleanup.sh                    # Cleanup script
├── artifacts/            # Local artifact files (optional, not committed)
├── one-click-deploy      # One-click deployment script
├── smoke-root.hcl        # Root Terragrunt configuration
└── README.md             # This file
```

## Tools

- **Terraform**: v1.14.0
- **Terragrunt**: v0.93.10
- **Juju Provider**: v1.0.0 (Terraform provider for Juju)
- **Dependencies**: jq, yq, python3

## Notes on Components
`cve-scanner` and `cos-configuration-k8s` are **INDEPENDENT**:
- They do NOT depend on each other
- No cross-dependencies in deployment order

## Local Charm Deployment

Currently CVE-Scanner charm and snap are not published to Charmhub/Snap Store. The charm should be deployed from local `.charm` file with the cve-scanner `.snap` attached as resource.
Deploying local `.charm` files:
1. Place `.charm` file in `artifacts/` directory
2. Place `.snap` file in `artifacts/` directory
3. Set `charm_source: file` in `environment-config.hcl`
4. Set `charm_path: ./artifacts/<charm-name>.charm`
5. Set `snap_path: ./artifacts/<snap-name>.snap`


## References
- [Juju Documentation](https://juju.is/docs)
- [Terraform Juju Provider](https://registry.terraform.io/providers/juju/juju/latest/docs)
- [Terragrunt Documentation](https://terragrunt.gruntwork.io/)
