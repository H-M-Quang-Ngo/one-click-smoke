#!/usr/bin/env bash
#
# Bootstrap script for Smoke Detector one-click deployment
# Check and installs required tools:
# Terraform, Terragrunt, Juju CLI, and other dependencies
#
# Usage: ./scripts/bootstrap.sh

set -euo pipefail

# Configuration
TERRAFORM_VERSION="1.14.0"
TERRAGRUNT_VERSION="0.93.10"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

install_dependencies() {
    log_info "Installing system dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        curl \
        wget \
        unzip \
        jq

    log_info "System dependencies installed"
}

install_terraform() {
    log_info "Checking Terraform installation..."

    if command -v terraform &> /dev/null; then
        INSTALLED_VERSION=$(terraform version -json | jq -r '.terraform_version')
        if [[ "$INSTALLED_VERSION" == "$TERRAFORM_VERSION" ]]; then
            log_info "Terraform $TERRAFORM_VERSION (exact match)"
        else
            log_warn "Terraform version mismatch:"
            log_warn "  Current installed: $INSTALLED_VERSION"
            log_warn "  This project is tested with: $TERRAFORM_VERSION"
            log_warn "  Things might not behave as expected with different versions"
        fi
        return 0
    fi

    # Install if not found
    log_info "Installing Terraform ${TERRAFORM_VERSION}..."

    cd /tmp
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    unzip -o "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/
    sudo chmod +x /usr/local/bin/terraform
    rm "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

    log_info "Terraform installed: $(terraform version | head -n1)"
}

install_terragrunt() {
    log_info "Checking Terragrunt installation..."

    if command -v terragrunt &> /dev/null; then
        INSTALLED_VERSION=$(terragrunt --version | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        if [[ "$INSTALLED_VERSION" == "$TERRAGRUNT_VERSION" ]]; then
            log_info "Terragrunt $TERRAGRUNT_VERSION (exact match)"
        else
            log_warn "Terragrunt version mismatch:"
            log_warn "  Current installed: $INSTALLED_VERSION"
            log_warn "  This project is tested with: $TERRAGRUNT_VERSION"
            log_warn "  Things might not behave as expected with different versions"
        fi
        return 0
    fi

    # Install if not found
    log_info "Installing Terragrunt ${TERRAGRUNT_VERSION}..."

    cd /tmp
    wget "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_amd64"
    sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
    sudo chmod +x /usr/local/bin/terragrunt

    log_info "Terragrunt installed: $(terragrunt --version | head -n1)"
}

install_juju() {
    log_info "Checking Juju CLI installation..."

    if command -v juju &> /dev/null; then
        log_info "Juju already installed: $(juju version)"
        return 0
    fi

    log_info "Installing Juju CLI..."

    sudo snap install juju --classic

    log_info "Juju installed: $(juju version)"
}

verify_installation() {
    log_info "Verifying installation..."

    local all_ok=true

    # Check Terraform
    if command -v terraform &> /dev/null; then
        INSTALLED_VERSION=$(terraform version -json | jq -r '.terraform_version')
        if [[ "$INSTALLED_VERSION" == "$TERRAFORM_VERSION" ]]; then
            log_info "Terraform ${TERRAFORM_VERSION} (exact match)"
        else
            log_info "Terraform ${INSTALLED_VERSION}"
            log_warn "  This project is tested with: $TERRAFORM_VERSION"
        fi
    else
        log_error "Terraform not found"
        all_ok=false
    fi

    # Check Terragrunt
    if command -v terragrunt &> /dev/null; then
        INSTALLED_VERSION=$(terragrunt --version | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        if [[ "$INSTALLED_VERSION" == "$TERRAGRUNT_VERSION" ]]; then
            log_info "Terragrunt ${TERRAGRUNT_VERSION} (exact match)"
        else
            log_info "Terragrunt ${INSTALLED_VERSION}"
            log_warn "  This project is tested with: $TERRAGRUNT_VERSION"
        fi
    else
        log_error "Terragrunt not found"
        all_ok=false
    fi

    # Check Juju
    if command -v juju &> /dev/null; then
        log_info " Juju $(juju version)"
    else
        log_error " Juju not found"
        all_ok=false
    fi

    # Check jq
    if command -v jq &> /dev/null; then
        log_info " jq"
    else
        log_error " jq not found"
        all_ok=false
    fi

    if [[ "$all_ok" == "true" ]]; then
        log_info "All tools installed successfully!"
        return 0
    else
        log_error "Some tools failed to install. Please check the errors above."
        return 1
    fi
}

main() {
    log_info "Starting bootstrap process..."
    log_info "Project root: $PROJECT_ROOT"

    install_dependencies
    install_terraform
    install_terragrunt
    install_juju
    verify_installation

    log_info "Bootstrap complete!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Configure environment:"
    log_info "     cd environments/default"
    log_info "     cp environment-config.template.hcl environment-config.hcl"
    log_info "     vim environment-config.hcl"
    log_info ""
    log_info "  2. Deploy components:"
    log_info "     ./one-click-deploy --env default --cve-scanner --cos-config"
    log_info ""
    log_info "  3. For more options:"
    log_info "     ./one-click-deploy --help"
}

main "$@"
