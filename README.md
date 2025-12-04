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
- Juju cloud that can deploy machines (LXD, MAAS, etc.) - could be the same as the one hosting [Landscape charm](https://github.com/canonical/landscape-charm)
- Existing COS deployment with exposed offers

## Start

### 1. Bootstrap Environment

Check/install required tools (Terraform, Terragrunt, Juju CLI):

```bash
./scripts/bootstrap.sh
```

### 2. Configure Environment
Copy and edit the environment configuration:

```bash
cd environments/default
cp environment-config.example.hcl environment-config.hcl
vim environment-config.hcl
```

### 3. Deploy Components
From the environment root, run Terragrunt to deploy all components:
```
terragrunt run-all plan   # Preview changes
terragrunt run-all apply  # Deploy all components
```

## Directory Structure

```
one-click-smoke/
├── modules/              # Reusable Terraform modules
│   ├── principal-charm-cos/          # Machine charm + grafana-agent + COS integration
│   ├── cve-scanner/                  # Setup for CVE Scanner charm (required configs, resources)
│   └── cos-configuration-k8s/        # COS configuration charm
├── environments/         # Environment-specific setup
│   └── default/
│       ├── environment-config.hcl    # Environment configurations
│       ├── 01-principal-deploy/      # Deploy machine charm and connect to COS (via grafana-agent)
│       │   └── terragrunt.hcl
│       └── 02-cve-scanner-specific/  # Configure CVE Scanner charm
│           └── terragrunt.hcl
│       └── cos-configuration-k8s/    # Deploy COS configuration charm and connect to COS
│           └── terragrunt.hcl
├── scripts/              # Helper scripts
│   ├── bootstrap.sh                  # Tool check/installation
│   ├── deploy-local-charm.sh         # Local charm deployment
│   ├── wait-for-application.sh       # Wait for Juju app ready
│   └── cleanup.sh                    # Cleanup script
├── artifacts/            # Local charm files
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
- They both connect to the SAME existing COS
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
