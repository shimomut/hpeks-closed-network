# HyperPod EKS Closed Network Makefile
# Utility commands for development and deployment

.PHONY: help init plan apply destroy copy-helm-repo clean-helm-repo submodule-update copy-images-to-ecr list-ecr-repos

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Submodule management
submodule-update: ## Initialize and update git submodules
	git submodule update --init --recursive
	git submodule update --remote

# Helm repository setup for local development
copy-helm-repo: ## Copy sagemaker-hyperpod-cli to /tmp/helm-repo for local development
	@echo "Copying sagemaker-hyperpod-cli to /tmp/helm-repo..."
	@rm -rf /tmp/helm-repo
	@cp -r sagemaker-hyperpod-cli /tmp/helm-repo
	@echo "✓ Copied sagemaker-hyperpod-cli to /tmp/helm-repo"

clean-helm-repo: ## Remove /tmp/helm-repo directory
	@echo "Cleaning up /tmp/helm-repo..."
	@rm -rf /tmp/helm-repo
	@echo "✓ Removed /tmp/helm-repo"

# Terraform operations (assuming working directory is the terraform module)
init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform init

plan: ## Run Terraform plan
	@echo "Running Terraform plan..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform plan

apply: ## Apply Terraform configuration
	@echo "Applying Terraform configuration..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform apply

destroy: ## Destroy Terraform infrastructure
	@echo "Destroying Terraform infrastructure..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform destroy

# Helm operations
helm-lint: ## Lint the Helm chart
	@echo "Linting Helm chart..."
	@helm lint sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/

helm-template: ## Generate Helm templates
	@echo "Generating Helm templates..."
	@helm template sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/

# ECR operations
list-ecr-repos: ## List ECR repositories that will be created (usage: make list-ecr-repos [REGION=us-east-2] [ACCOUNT_ID=auto])
	@./tools/list-ecr-repos.sh $(REGION) $(ACCOUNT_ID)

copy-images-to-ecr: ## Copy container images to ECR repositories (usage: make copy-images-to-ecr [REGION=us-east-2] [ACCOUNT_ID=auto])
	@echo "Copying container images to ECR..."
	@./tools/copy-images-to-ecr.sh $(REGION) $(ACCOUNT_ID)

# Development utilities
dev-setup: submodule-update copy-helm-repo ## Setup development environment
	@echo "✓ Development environment ready"

clean: clean-helm-repo ## Clean up temporary files and directories
	@echo "✓ Cleanup complete"