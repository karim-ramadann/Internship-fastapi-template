# Makefile for CloudFormation Infrastructure Deployment
# Usage: make <target> ENV=<environment>
# Example: make deploy ENV=dev

.PHONY: help validate validate-stack deploy deploy-stack destroy destroy-stack status status-stack outputs outputs-stack

# Default environment
ENV ?= dev

# Stack definitions (name:template)
STACKS := 01-network:01-network.yaml \
          02-database:02-database.yaml \
          03-storage:03-storage.yaml \
          04-compute:04-compute.yaml \
          05-async:05-async.yaml \
          06-monitoring:06-monitoring.yaml

# Scripts directory
SCRIPTS_DIR := scripts
INFRA_DIR := .

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "CloudFormation Infrastructure Deployment"
	@echo ""
	@echo "Usage: make <target> ENV=<environment>"
	@echo "Environments: dev, staging, prod"
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

validate: ## Validate all CloudFormation templates
	@echo "$(YELLOW)Validating all CloudFormation templates...$(NC)"
	@for stack_info in $(STACKS); do \
		IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
		echo "Validating $$template_file..."; \
		$(SCRIPTS_DIR)/validate-stack.sh $$template_file $(ENV) || exit 1; \
	done
	@echo "$(GREEN)All templates validated successfully$(NC)"

validate-stack: ## Validate a specific stack (usage: make validate-stack STACK=01-network ENV=dev)
	@if [ -z "$(STACK)" ]; then \
		echo "$(RED)Error: STACK parameter required$(NC)"; \
		echo "Usage: make validate-stack STACK=01-network ENV=dev"; \
		exit 1; \
	fi
	@template_file="$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):" | cut -d':' -f2)"; \
	if [ -z "$$template_file" ]; then \
		echo "$(RED)Error: Stack $(STACK) not found$(NC)"; \
		exit 1; \
	fi; \
	echo "$(YELLOW)Validating $$template_file...$(NC)"; \
	$(SCRIPTS_DIR)/validate-stack.sh $$template_file $(ENV)

deploy: ## Deploy all stacks for the specified environment
	@echo "$(YELLOW)Deploying all stacks for environment: $(ENV)$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)WARNING: Deploying to PRODUCTION$(NC)"; \
		read -p "Are you sure? [y/N] " -n 1 -r; \
		echo; \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
			echo "$(YELLOW)Deployment cancelled$(NC)"; \
			exit 1; \
		fi; \
	fi
	@$(SCRIPTS_DIR)/deploy-all.sh $(ENV)

deploy-stack: ## Deploy a specific stack (usage: make deploy-stack STACK=01-network ENV=dev)
	@if [ -z "$(STACK)" ]; then \
		echo "$(RED)Error: STACK parameter required$(NC)"; \
		echo "Usage: make deploy-stack STACK=01-network ENV=dev"; \
		exit 1; \
	fi
	@stack_info=$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):"); \
	if [ -z "$$stack_info" ]; then \
		echo "$(RED)Error: Stack $(STACK) not found$(NC)"; \
		exit 1; \
	fi; \
	IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
	echo "$(YELLOW)Deploying stack: $(ENV)-$$stack_name$(NC)"; \
	$(SCRIPTS_DIR)/deploy-stack.sh $$stack_name $$template_file $(ENV)

destroy: ## Destroy all stacks (WARNING: Destructive operation!)
	@echo "$(RED)WARNING: This will destroy ALL stacks for environment: $(ENV)$(NC)"
	@if [ "$(ENV)" = "prod" ]; then \
		echo "$(RED)ERROR: Cannot destroy production without --force$(NC)"; \
		exit 1; \
	fi
	@read -p "Are you absolutely sure? Type 'yes' to continue: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "$(YELLOW)Destruction cancelled$(NC)"; \
		exit 0; \
	fi
	@echo "$(YELLOW)Destroying stacks in reverse order...$(NC)"
	@for stack_info in $$(echo $(STACKS) | tr ' ' '\n' | tac); do \
		IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
		echo "Destroying $(ENV)-$$stack_name..."; \
		$(SCRIPTS_DIR)/destroy-stack.sh $$stack_name $(ENV) --force || true; \
	done
	@echo "$(GREEN)All stacks destroyed$(NC)"

destroy-stack: ## Destroy a specific stack (usage: make destroy-stack STACK=01-network ENV=dev)
	@if [ -z "$(STACK)" ]; then \
		echo "$(RED)Error: STACK parameter required$(NC)"; \
		echo "Usage: make destroy-stack STACK=01-network ENV=dev"; \
		exit 1; \
	fi
	@stack_info=$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):"); \
	if [ -z "$$stack_info" ]; then \
		echo "$(RED)Error: Stack $(STACK) not found$(NC)"; \
		exit 1; \
	fi; \
	IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
	echo "$(YELLOW)Destroying stack: $(ENV)-$$stack_name$(NC)"; \
	$(SCRIPTS_DIR)/destroy-stack.sh $$stack_name $(ENV)

status: ## Show status of all stacks
	@echo "$(YELLOW)Stack Status for environment: $(ENV)$(NC)"
	@echo ""
	@for stack_info in $(STACKS); do \
		IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
		echo "=== $$stack_name ==="; \
		$(SCRIPTS_DIR)/stack-status.sh $$stack_name $(ENV) || echo "  Stack does not exist"; \
		echo ""; \
	done

status-stack: ## Show status of a specific stack (usage: make status-stack STACK=01-network ENV=dev)
	@if [ -z "$(STACK)" ]; then \
		echo "$(RED)Error: STACK parameter required$(NC)"; \
		echo "Usage: make status-stack STACK=01-network ENV=dev"; \
		exit 1; \
	fi
	@stack_info=$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):"); \
	if [ -z "$$stack_info" ]; then \
		echo "$(RED)Error: Stack $(STACK) not found$(NC)"; \
		exit 1; \
	fi; \
	IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
	$(SCRIPTS_DIR)/stack-status.sh $$stack_name $(ENV) --outputs

outputs: ## Show outputs of all stacks
	@echo "$(YELLOW)Stack Outputs for environment: $(ENV)$(NC)"
	@echo ""
	@for stack_info in $(STACKS); do \
		IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
		echo "=== $$stack_name ==="; \
		$(SCRIPTS_DIR)/stack-status.sh $$stack_name $(ENV) --outputs || echo "  Stack does not exist"; \
		echo ""; \
	done

outputs-stack: ## Show outputs of a specific stack (usage: make outputs-stack STACK=01-network ENV=dev)
	@if [ -z "$(STACK)" ]; then \
		echo "$(RED)Error: STACK parameter required$(NC)"; \
		echo "Usage: make outputs-stack STACK=01-network ENV=dev"; \
		exit 1; \
	fi
	@stack_info=$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):"); \
	if [ -z "$$stack_info" ]; then \
		echo "$(RED)Error: Stack $(STACK) not found$(NC)"; \
		exit 1; \
	fi; \
	IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
	$(SCRIPTS_DIR)/stack-status.sh $$stack_name $(ENV) --outputs

# CI/CD specific targets (for GitHub Actions)
ci-validate: ## Validate all templates (CI/CD target)
	@make validate ENV=$(ENV)

ci-deploy: ## Deploy all stacks (CI/CD target, no prompts)
	@$(SCRIPTS_DIR)/deploy-all.sh $(ENV)

ci-deploy-stack: ## Deploy specific stack (CI/CD target, no prompts)
	@if [ -z "$(STACK)" ]; then \
		echo "Error: STACK parameter required"; \
		exit 1; \
	fi
	@stack_info=$$(echo $(STACKS) | tr ' ' '\n' | grep "^$(STACK):"); \
	if [ -z "$$stack_info" ]; then \
		echo "Error: Stack $(STACK) not found"; \
		exit 1; \
	fi; \
	IFS=':' read -r stack_name template_file <<< "$$stack_info"; \
	$(SCRIPTS_DIR)/deploy-stack.sh $$stack_name $$template_file $(ENV)
