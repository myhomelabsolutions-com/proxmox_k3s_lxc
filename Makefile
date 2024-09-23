.PHONY: help init plan apply destroy provision clean k3s-install k3s-uninstall

# Colors for terminal output
GREEN := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET := $(shell tput -Txterm sgr0)

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "$(GREEN)Initializing Terraform...$(RESET)"
	cd terraform && terraform init

plan: ## Create Terraform plan
	@echo "$(GREEN)Creating Terraform plan...$(RESET)"
	cd terraform && terraform plan

apply: ## Apply Terraform changes
	@echo "$(GREEN)Applying Terraform changes...$(RESET)"
	cd terraform && terraform apply -auto-approve

destroy: ## Destroy Terraform-managed infrastructure
	@echo "$(GREEN)Destroying Terraform-managed infrastructure...$(RESET)"
	cd terraform && terraform destroy -auto-approve

provision: ## Run Ansible playbook to install k3s
	@echo "$(GREEN)Running Ansible playbook to install k3s...$(RESET)"
	ansible-playbook -i terraform/inventory.ini ansible/k3s-install.yml

k3s-install: apply provision ## Create infrastructure and install k3s

k3s-uninstall: ## Uninstall k3s from all nodes
	@echo "$(GREEN)Uninstalling k3s from all nodes...$(RESET)"
	ansible-playbook -i terraform/inventory.ini ansible/k3s-uninstall.yml

clean: destroy ## Destroy infrastructure and clean up files
	@echo "$(GREEN)Cleaning up Terraform files...$(RESET)"
	rm -rf terraform/.terraform terraform/*.tfstate terraform/*.tfstate.backup

# Default target
.DEFAULT_GOAL := help
