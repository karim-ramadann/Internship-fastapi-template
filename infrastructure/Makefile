# Makefile for Terraform infrastructure
# Usage: make <target> ENV=<environment>
# Example: make plan ENV=dev
# Run from repo root or infrastructure/: make -C infrastructure plan ENV=dev

.PHONY: help plan fmt validate tflint trivy tfdocs init init-validate check

# Default environment (dev, staging, production)
ENV ?= dev

TF_DIR := terraform

# Run from repo root: make -C infrastructure <target>
# Or: cd infrastructure && make <target>

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m

help: ## Show this help
	@echo "Terraform infrastructure targets (ENV=$(ENV))"
	@echo ""
	@echo "Usage: make <target> ENV=<environment>"
	@echo "Environments: dev, staging, production"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2}'

init: ## Initialize Terraform with backend (required for plan/apply)
	@echo "$(YELLOW)Initializing Terraform (ENV=$(ENV))...$(NC)"
	@cd $(TF_DIR) && terraform init -backend-config=environments/$(ENV)/backend.hcl

init-validate: ## Initialize Terraform without backend (for validate only)
	@cd $(TF_DIR) && terraform init -backend=false

plan: init ## Run terraform plan for the selected environment
	@echo "$(YELLOW)Running terraform plan (ENV=$(ENV))...$(NC)"
	@cd $(TF_DIR) && terraform plan -var-file=environments/$(ENV)/terraform.tfvars

fmt: ## Format .tf files (terraform fmt -recursive)
	@echo "$(YELLOW)Formatting Terraform files...$(NC)"
	@cd $(TF_DIR) && terraform fmt -recursive
	@echo "$(GREEN)Done$(NC)"

validate: init-validate ## Validate Terraform configuration (syntax and provider)
	@echo "$(YELLOW)Validating Terraform...$(NC)"
	@cd $(TF_DIR) && terraform validate
	@echo "$(GREEN)Validation passed$(NC)"

tflint: ## Run tflint on Terraform files
	@echo "$(YELLOW)Running tflint...$(NC)"
	@cd $(TF_DIR) && tflint --recursive
	@echo "$(GREEN)Done$(NC)"

trivy: ## Run trivy filesystem scan on Terraform for security/misconfig
	@echo "$(YELLOW)Running trivy on Terraform...$(NC)"
	@cd $(TF_DIR) && trivy fs --scanners misconfig .
	@echo "$(GREEN)Done$(NC)"

tfdocs: ## Generate/update Terraform docs (terraform-docs) in READMEs
	@echo "$(YELLOW)Updating Terraform docs...$(NC)"
	@command -v terraform-docs >/dev/null 2>&1 || (echo "terraform-docs not installed (e.g. brew install terraform-docs)" && exit 1)
	@cd $(TF_DIR) && terraform-docs markdown table --output-file README.md --output-mode inject .
	@cd $(TF_DIR) && for d in modules/*/; do [ -f "$$d/README.md" ] && terraform-docs markdown table --output-file README.md --output-mode inject "$$d" || true; done
	@echo "$(GREEN)Done$(NC)"

# Run all checks (fmt, validate, tflint, trivy) — useful for CI and pre-commit
check: fmt validate tflint trivy ## Run fmt, validate, tflint, trivy
