# HyperPod EKS Closed Network Makefile
# Utility commands for development and deployment

.PHONY: help init plan apply destroy copy-helm-repo clean-helm-repo submodule-update copy-images-to-ecr list-ecr-repos helm-lint helm-template helm-install helm-list-releases helm-uninstall

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

helm-install: ## Install Helm chart with validation (usage: make helm-install [RELEASE=hyperpod-dependencies] [NAMESPACE=kube-system])
	@RELEASE_NAME="hyperpod-dependencies"; \
	if [ -n "$(RELEASE)" ]; then \
		RELEASE_NAME="$(RELEASE)"; \
	fi; \
	NAMESPACE_NAME="kube-system"; \
	if [ -n "$(NAMESPACE)" ]; then \
		NAMESPACE_NAME="$(NAMESPACE)"; \
	fi; \
	NAMESPACE_FLAG="-n $$NAMESPACE_NAME"; \
	echo "Installing Helm chart for release: $$RELEASE_NAME in namespace: $$NAMESPACE_NAME..."; \
	echo "1. Updating chart dependencies..."; \
	helm dependency update sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/; \
	echo "2. Linting chart..."; \
	helm lint sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/; \
	echo "3. Validating templates..."; \
	helm template $$RELEASE_NAME sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/ $$NAMESPACE_FLAG --validate > /dev/null; \
	echo "4. Installing Helm chart..."; \
	helm install $$RELEASE_NAME sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/ $$NAMESPACE_FLAG ; \
	echo "✓ Helm chart installed successfully for release: $$RELEASE_NAME in namespace: $$NAMESPACE_NAME"

helm-list-releases: ## List Helm releases (usage: make helm-list-releases [NAMESPACE=kube-system])
	@NAMESPACE_NAME="kube-system"; \
	if [ -n "$(NAMESPACE)" ]; then \
		NAMESPACE_NAME="$(NAMESPACE)"; \
	fi; \
	NAMESPACE_FLAG="-n $$NAMESPACE_NAME"; \
	echo "Listing Helm releases in namespace: $$NAMESPACE_NAME..."; \
	echo "Command: helm list $$NAMESPACE_FLAG"; \
	helm list $$NAMESPACE_FLAG

helm-uninstall: ## Uninstall Helm release (usage: make helm-uninstall [RELEASE=hyperpod-dependencies] [NAMESPACE=kube-system])
	@RELEASE_NAME="hyperpod-dependencies"; \
	if [ -n "$(RELEASE)" ]; then \
		RELEASE_NAME="$(RELEASE)"; \
	fi; \
	NAMESPACE_NAME="kube-system"; \
	if [ -n "$(NAMESPACE)" ]; then \
		NAMESPACE_NAME="$(NAMESPACE)"; \
	fi; \
	NAMESPACE_FLAG="-n $$NAMESPACE_NAME"; \
	echo "Uninstalling Helm release: $$RELEASE_NAME from namespace: $$NAMESPACE_NAME..."; \
	if helm list -q $$NAMESPACE_FLAG | grep -q "^$$RELEASE_NAME$$"; then \
		helm uninstall $$RELEASE_NAME $$NAMESPACE_FLAG; \
		echo "✓ Successfully uninstalled release: $$RELEASE_NAME from namespace: $$NAMESPACE_NAME"; \
	else \
		echo "Release '$$RELEASE_NAME' not found in namespace '$$NAMESPACE_NAME'. Available releases:"; \
		helm list $$NAMESPACE_FLAG; \
	fi

# ECR operations
list-ecr-repos: ## List ECR repositories that will be created (usage: make list-ecr-repos [REGION=us-east-2] [ACCOUNT_ID=auto])
	@./tools/list-ecr-repos.sh $(REGION) $(ACCOUNT_ID)

copy-images-to-ecr: ## Copy container images to ECR repositories (usage: make copy-images-to-ecr [REGION=us-east-2] [ACCOUNT_ID=auto])
	@echo "Copying container images to ECR..."
	@./tools/copy-images-to-ecr.sh $(REGION) $(ACCOUNT_ID)

update-values-with-ecr: ## Update Helm values.yaml files with ECR image references (usage: make update-values-with-ecr [REGION=us-east-2] [ACCOUNT_ID=auto])
	@echo "Updating Helm values.yaml files with ECR image references..."
	@./tools/update-values-with-ecr.py $(REGION) $(ACCOUNT_ID)

setup-ecr-images: copy-images-to-ecr update-values-with-ecr ## Copy images to ECR and update values.yaml files (usage: make setup-ecr-images [REGION=us-east-2] [ACCOUNT_ID=auto])
	@echo "✓ ECR setup complete - images copied and values.yaml files updated"

# Development utilities
dev-setup: submodule-update copy-helm-repo ## Setup development environment
	@echo "✓ Development environment ready"

clean: clean-helm-repo ## Clean up temporary files and directories
	@echo "✓ Cleanup complete"