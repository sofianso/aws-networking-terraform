.PHONY: help plan apply destroy format validate clean init

# Default target
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Environment selection (default: networking)
ENV ?= networking
REGION ?= ap-southeast-2
COMPONENT ?= vpc

# Terragrunt working directory
TG_DIR := $(ENV)/$(REGION)/$(COMPONENT)

help: ## Display this help message
	@echo "$(CYAN)AWS Networking Terraform/Terragrunt Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Usage:$(NC)"
	@echo "  make [target] ENV=[environment] REGION=[region] COMPONENT=[component]"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(NC)"
	@echo "  make plan ENV=networking REGION=ap-southeast-2 COMPONENT=transit-gateway"
	@echo "  make apply ENV=non-prod REGION=ap-southeast-2 COMPONENT=vpc"
	@echo "  make plan-all ENV=prod"
	@echo ""
	@echo "$(GREEN)Environments:$(NC)"
	@echo "  - networking (default)"
	@echo "  - non-prod"
	@echo "  - prod"

init: ## Initialize Terragrunt for the specified component
	@echo "$(CYAN)Initializing $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt init

plan: ## Run Terragrunt plan for the specified component
	@echo "$(CYAN)Running plan for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt plan

apply: ## Run Terragrunt apply for the specified component
	@echo "$(YELLOW)Running apply for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt apply

apply-auto: ## Run Terragrunt apply with auto-approve
	@echo "$(RED)Running apply with auto-approve for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt apply -auto-approve

destroy: ## Run Terragrunt destroy for the specified component
	@echo "$(RED)Running destroy for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt destroy

destroy-auto: ## Run Terragrunt destroy with auto-approve
	@echo "$(RED)Running destroy with auto-approve for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt destroy -auto-approve

plan-all: ## Run Terragrunt plan for all components in the environment
	@echo "$(CYAN)Running plan for all components in $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt run-all plan

apply-all: ## Run Terragrunt apply for all components in the environment
	@echo "$(YELLOW)Running apply for all components in $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt run-all apply

apply-all-auto: ## Run Terragrunt apply for all components with auto-approve
	@echo "$(RED)Running apply with auto-approve for all components in $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt run-all apply -auto-approve

destroy-all: ## Run Terragrunt destroy for all components in the environment
	@echo "$(RED)Running destroy for all components in $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt run-all destroy

format: ## Format all Terraform files
	@echo "$(CYAN)Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .
	@echo "$(GREEN)✓ Formatting complete$(NC)"

validate: ## Validate Terragrunt configuration
	@echo "$(CYAN)Validating $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt validate

validate-all: ## Validate all Terragrunt configurations
	@echo "$(CYAN)Validating all configurations...$(NC)"
	@find . -name "terragrunt.hcl" -not -path "*/.*" -exec dirname {} \; | sort -u | while read dir; do \
		echo "$(CYAN)Validating $$dir...$(NC)"; \
		cd $$dir && terragrunt validate || exit 1; \
	done
	@echo "$(GREEN)✓ All validations passed$(NC)"

clean: ## Clean Terragrunt cache and temporary files
	@echo "$(CYAN)Cleaning Terragrunt cache and temporary files...$(NC)"
	@find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

output: ## Show Terragrunt outputs
	@echo "$(CYAN)Showing outputs for $(ENV)/$(REGION)/$(COMPONENT)...$(NC)"
	cd $(TG_DIR) && terragrunt output

output-all: ## Show all Terragrunt outputs for the environment
	@echo "$(CYAN)Showing all outputs for $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt run-all output

graph: ## Generate dependency graph
	@echo "$(CYAN)Generating dependency graph for $(ENV)/$(REGION)...$(NC)"
	cd $(ENV)/$(REGION) && terragrunt graph-dependencies | dot -Tpng > dependency-graph.png
	@echo "$(GREEN)✓ Graph saved to $(ENV)/$(REGION)/dependency-graph.png$(NC)"

check-fmt: ## Check if Terraform files are formatted correctly
	@echo "$(CYAN)Checking Terraform formatting...$(NC)"
	@if terraform fmt -check -recursive . > /dev/null 2>&1; then \
		echo "$(GREEN)✓ All files are properly formatted$(NC)"; \
	else \
		echo "$(RED)✗ Some files need formatting. Run 'make format' to fix.$(NC)"; \
		terraform fmt -check -recursive .; \
		exit 1; \
	fi

# Quick access targets for common operations
networking-tgw-plan: ## Quick plan for networking Transit Gateway
	@$(MAKE) plan ENV=networking COMPONENT=transit-gateway

networking-tgw-apply: ## Quick apply for networking Transit Gateway
	@$(MAKE) apply ENV=networking COMPONENT=transit-gateway

networking-vpc-plan: ## Quick plan for networking VPC
	@$(MAKE) plan ENV=networking COMPONENT=vpc

networking-vpc-apply: ## Quick apply for networking VPC
	@$(MAKE) apply ENV=networking COMPONENT=vpc

non-prod-plan: ## Quick plan for non-prod VPC
	@$(MAKE) plan ENV=non-prod COMPONENT=vpc

non-prod-apply: ## Quick apply for non-prod VPC
	@$(MAKE) apply ENV=non-prod COMPONENT=vpc

prod-plan: ## Quick plan for prod VPC
	@$(MAKE) plan ENV=prod COMPONENT=vpc

prod-apply: ## Quick apply for prod VPC
	@$(MAKE) apply ENV=prod COMPONENT=vpc

github-oidc-plan: ## Quick plan for GitHub OIDC role
	@$(MAKE) plan ENV=networking COMPONENT=github-oidc

github-oidc-apply: ## Quick apply for GitHub OIDC role
	@$(MAKE) apply ENV=networking COMPONENT=github-oidc
