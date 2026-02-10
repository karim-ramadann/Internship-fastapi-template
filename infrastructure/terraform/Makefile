.PHONY: help init plan apply destroy fmt validate docs docs-modules clean

# Default target
help:
	@echo "Available targets:"
	@echo "  init          - Initialize Terraform"
	@echo "  plan          - Run terraform plan"
	@echo "  apply         - Run terraform apply"
	@echo "  destroy       - Run terraform destroy"
	@echo "  fmt           - Format all Terraform files"
	@echo "  validate      - Validate Terraform configuration"
	@echo "  docs          - Generate documentation for root and all modules"
	@echo "  docs-modules  - Generate documentation for modules only"
	@echo "  clean         - Clean Terraform cache files"

# Initialize Terraform
init:
	terraform init

# Terraform plan
plan:
	terraform plan

# Terraform apply
apply:
	terraform apply

# Terraform destroy
destroy:
	terraform destroy

# Format Terraform files
fmt:
	terraform fmt -recursive

# Validate configuration
validate:
	terraform validate

# Generate documentation using terraform-docs
docs: docs-root docs-modules

docs-root:
	@echo "Generating root documentation..."
	@if command -v terraform-docs >/dev/null 2>&1; then \
		terraform-docs markdown table --output-file README.md --output-mode inject .; \
	else \
		echo "terraform-docs is not installed. Install it from: https://terraform-docs.io/"; \
		exit 1; \
	fi

docs-modules:
	@echo "Generating module documentation..."
	@for dir in modules/*/; do \
		if [ -f "$$dir.terraform-docs.yml" ] || [ -f "$$dir/.terraform-docs.yml" ]; then \
			echo "Generating docs for $$dir"; \
			terraform-docs markdown table --output-file README.md --output-mode inject "$$dir"; \
		else \
			echo "Skipping $$dir (no .terraform-docs.yml found)"; \
		fi \
	done

# Clean Terraform cache
clean:
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate
	rm -f terraform.tfstate.backup
	rm -f crash.log
