# Technology Stack

## Primary Technologies
- **Terraform**: Infrastructure as Code for AWS resource provisioning
- **Helm**: Kubernetes package manager for application deployment
- **AWS EKS**: Kubernetes service for container orchestration
- **Amazon SageMaker HyperPod**: Distributed ML training platform
- **Make**: Build automation and utility command management

## Project Structure
- **Git Submodules**: Two submodules providing base configurations
  - `awsome-distributed-training`: Source for Terraform modules
  - `sagemaker-hyperpod-cli`: Source for Helm charts
- **Customization Focus**: Only specific paths are modified, not entire submodules

## Common Commands
```bash
# Submodule management
git submodule update --init --recursive
git submodule update --remote

# Build and deployment (via Makefile)
make help          # Show available commands
make init          # Initialize environment
make plan          # Terraform plan
make apply         # Deploy infrastructure
make destroy       # Tear down infrastructure

# ECR image management (for closed networks)
make list-ecr-repos         # Preview ECR repositories
make copy-images-to-ecr     # Copy container images to ECR
make update-values-with-ecr # Update top-level values.yaml with ECR overrides
make setup-ecr-images       # Complete ECR setup (copy + update values)

# Terraform operations
terraform init
terraform plan
terraform apply
terraform destroy

# Helm operations
helm lint ./path/to/chart
helm template ./path/to/chart
helm install release-name ./path/to/chart
```

## File Types
- **Terraform files**: `.tf`, `.tfvars`, `.tfstate`
- **Helm charts**: `Chart.yaml`, `values.yaml`, template files
- **Makefile**: Utility commands and automation
- **Shell scripts**: `.sh` files in `tools/` directory for utilities
- **Configuration files**: `.conf` files for tool configurations