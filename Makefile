# HyperPod EKS Closed Network Makefile
# Utility commands for development and deployment
#
# Deployment Types:
# 1. Full Stack Deployment: Creates new VPC, subnets, and all resources (use terraform.tfvars)
# 2. Two-Phase Deployment: Uses existing VPC/subnets created by infrastructure stack (use terraform-with-existing-vpc.tfvars)
#    - Phase 1: Deploy infrastructure stack with 'make deploy-infra-stack'
#    - Phase 2: Deploy HyperPod cluster with 'make deploy-cluster-existing-vpc'

.PHONY: help init plan apply destroy plan-full-stack apply-full-stack plan-existing-vpc apply-existing-vpc submodule-update copy-images-to-ecr list-ecr-repos helm-lint helm-template helm-install helm-list-releases helm-uninstall infra-init infra-plan infra-apply infra-destroy infra-output infra-tfvars deploy-infra-stack deploy-cluster-existing-vpc destroy-all deploy-e2e-existing-vpc clean

# Default target
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Submodule management
submodule-update: ## Initialize and update git submodules
	git submodule update --init --recursive
	git submodule update --remote

# Main cluster Terraform operations
init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform init

# Deployment type specific targets
plan-full-stack: ## Run Terraform plan for full stack deployment (creates new VPC)
	@echo "Running Terraform plan for full stack deployment..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform plan -var-file="terraform.tfvars"

apply-full-stack: ## Apply Terraform configuration for full stack deployment (creates new VPC)
	@echo "Applying Terraform configuration for full stack deployment..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform apply -var-file="terraform.tfvars"

plan-existing-vpc: ## Run Terraform plan for existing VPC deployment (2-phase deployment)
	@echo "Running Terraform plan for existing VPC deployment..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform plan -var-file="terraform-with-existing-vpc.tfvars"

apply-existing-vpc: ## Apply Terraform configuration for existing VPC deployment (2-phase deployment)
	@echo "Applying Terraform configuration for existing VPC deployment..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform apply -var-file="terraform-with-existing-vpc.tfvars"

plan: ## Run Terraform plan (usage: make plan [TFVARS=terraform-with-existing-vpc.tfvars])
	@echo "Running Terraform plan..."
	@TFVARS_FILE="terraform.tfvars"; \
	if [ -n "$(TFVARS)" ]; then \
		TFVARS_FILE="$(TFVARS)"; \
	fi; \
	echo "Using tfvars file: $$TFVARS_FILE"; \
	cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform plan -var-file="$$TFVARS_FILE"

apply: ## Apply Terraform configuration (usage: make apply [TFVARS=terraform-with-existing-vpc.tfvars])
	@echo "Applying Terraform configuration..."
	@TFVARS_FILE="terraform.tfvars"; \
	if [ -n "$(TFVARS)" ]; then \
		TFVARS_FILE="$(TFVARS)"; \
	fi; \
	echo "Using tfvars file: $$TFVARS_FILE"; \
	cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform apply -var-file="$$TFVARS_FILE"

destroy: ## Destroy Terraform infrastructure (usage: make destroy [TFVARS=terraform-with-existing-vpc.tfvars])
	@echo "Destroying Terraform infrastructure..."
	@TFVARS_FILE="terraform.tfvars"; \
	if [ -n "$(TFVARS)" ]; then \
		TFVARS_FILE="$(TFVARS)"; \
	fi; \
	echo "Using tfvars file: $$TFVARS_FILE"; \
	cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform destroy -var-file="$$TFVARS_FILE"

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

# Infrastructure stack operations (existing VPC testing)
infra-init: ## Initialize infrastructure stack Terraform
	@echo "Initializing infrastructure stack Terraform..."
	@cd existing-vpc-tf && terraform init

infra-plan: ## Run Terraform plan for infrastructure stack
	@echo "Running Terraform plan for infrastructure stack..."
	@cd existing-vpc-tf && terraform plan

infra-apply: ## Apply infrastructure stack Terraform configuration
	@echo "Applying infrastructure stack Terraform configuration..."
	@cd existing-vpc-tf && terraform apply

infra-destroy: ## Destroy infrastructure stack
	@echo "Destroying infrastructure stack..."
	@cd existing-vpc-tf && terraform destroy

infra-output: ## Show infrastructure stack outputs
	@echo "Infrastructure stack outputs:"
	@cd existing-vpc-tf && terraform output

infra-tfvars: ## Generate tfvars snippet for main cluster deployment
	@echo "=== Copy the following to your main cluster terraform.tfvars ==="
	@cd existing-vpc-tf && terraform output -raw terraform_tfvars_snippet

# Combined deployment workflow for existing VPC testing
deploy-infra-stack: infra-init infra-apply ## Deploy complete infrastructure stack
	@echo "✓ Infrastructure stack deployed successfully"
	@echo ""
	@echo "Next steps:"
	@echo "1. Run 'make infra-tfvars' to get the configuration snippet"
	@echo "2. Copy the output to awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform-with-existing-vpc.tfvars"
	@echo "3. Run 'make deploy-cluster-existing-vpc' to deploy HyperPod with existing infrastructure"

deploy-cluster-existing-vpc: ## Deploy HyperPod cluster using existing infrastructure (run deploy-infra-stack first)
	@echo "Deploying HyperPod cluster with existing infrastructure..."
	@echo "Checking if infrastructure outputs are available..."
	@cd existing-vpc-tf && terraform output vpc_id > /dev/null 2>&1 || (echo "❌ Infrastructure stack not deployed. Run 'make deploy-infra-stack' first." && exit 1)
	@echo "✓ Infrastructure stack detected"
	@echo "Initializing main cluster Terraform..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform init
	@echo "Planning main cluster deployment with existing VPC configuration..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform plan -var-file="terraform-with-existing-vpc.tfvars"
	@echo "Applying main cluster deployment..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform apply -var-file="terraform-with-existing-vpc.tfvars"

destroy-all: ## Destroy both cluster and infrastructure (in correct order)
	@echo "Destroying complete deployment..."
	@echo "1. Destroying HyperPod cluster first..."
	@cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf && terraform destroy -var-file="terraform-with-existing-vpc.tfvars" || echo "Cluster already destroyed or not deployed"
	@echo "2. Destroying infrastructure stack..."
	@cd existing-vpc-tf && terraform destroy || echo "Infrastructure already destroyed or not deployed"
	@echo "✓ Complete cleanup finished"

# Automated end-to-end deployment for existing VPC testing
deploy-e2e-existing-vpc: ## End-to-end deployment: infrastructure + cluster with existing VPC setup
	@echo "Starting end-to-end deployment with existing VPC setup..."
	@echo ""
	@echo "Step 1: Deploying infrastructure stack..."
	@$(MAKE) deploy-infra-stack
	@echo ""
	@echo "Step 2: Extracting infrastructure configuration..."
	@cd existing-vpc-tf && terraform output -raw terraform_tfvars_snippet > infra-config.tfvars
	@echo "✓ Infrastructure configuration saved to existing-vpc-tf/infra-config.tfvars"
	@echo ""
	@echo "Step 3: Updating main cluster configuration..."
	@echo "# Generated infrastructure configuration" > awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/existing-vpc.auto.tfvars
	@cd existing-vpc-tf && terraform output -raw terraform_tfvars_snippet >> ../awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/existing-vpc.auto.tfvars
	@echo "✓ Main cluster configuration updated with infrastructure IDs"
	@echo ""
	@echo "Step 4: Deploying HyperPod cluster..."
	@$(MAKE) deploy-cluster-existing-vpc
	@echo ""
	@echo "🎉 End-to-end deployment completed successfully!"
	@echo ""
	@echo "Infrastructure details:"
	@$(MAKE) infra-output

clean: ## Clean up temporary files and directories
	@echo "Cleaning up temporary files..."
	@rm -f existing-vpc-tf/infra-config.tfvars
	@rm -f awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/existing-vpc.auto.tfvars
	@echo "✓ Cleanup complete"