# HyperPod EKS Closed Network

This project customizes Terraform modules and Helm charts to deploy Amazon SageMaker HyperPod on Amazon EKS in a closed network environment. It leverages existing open-source components from AWS and modifies them specifically for secure, isolated deployments.

## Overview

### Key Components
- **Terraform customizations**: Modified files from `awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf`
- **Helm chart customizations**: Modified files from `sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart`
- **Closed network architecture**: Specialized configurations for air-gapped environments

### Project Structure
```
├── .git/                    # Git version control
├── .gitmodules              # Git submodule configuration
├── .gitignore              # Comprehensive gitignore
├── .kiro/                  # Kiro AI assistant configuration
│   └── steering/           # AI guidance documents
├── awsome-distributed-training/  # Submodule (only specific paths modified)
│   └── 1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/
├── sagemaker-hyperpod-cli/ # Submodule (only specific paths modified)
│   └── helm_chart/HyperPodHelmChart/
├── tools/                  # Utility scripts
│   ├── ecr-images.conf     # ECR image configuration
│   ├── copy-images-to-ecr.sh # ECR image copy script
│   ├── list-ecr-repos.sh   # ECR repository listing script
│   └── update-values-with-ecr.py # Update top-level values.yaml with ECR overrides
├── Makefile               # Utility commands and automation
├── LICENSE                # MIT License
└── README.md             # This file
```

## Getting Started

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed and running
- Terraform installed
- Helm installed
- Git with submodule support
- Python 3 with `ruamel.yaml` package (for ECR values update script)

### Initial Setup
```bash
# Clone repository with submodules
git clone --recursive <repository-url>
cd hpeks-closed-network

# Install Python dependencies for ECR values update script
python3 -m pip install ruamel.yaml

# Initialize development environment
make dev-setup
```

## Container Image Management

For closed network deployments, you'll need to copy required container images to your private ECR repositories.

### Required Images
- `aws-efa-k8s-device-plugin` - AWS EFA Kubernetes Device Plugin
- `hyperpod-health-monitoring-agent` - HyperPod Health Monitoring Agent
- `nvidia-k8s-device-plugin` - NVIDIA Kubernetes Device Plugin
- `mpi-operator` - MPI Operator for distributed training

### ECR Operations

#### Preview ECR repositories
```bash
# List repositories that will be created (default: us-east-2)
make list-ecr-repos

# With custom region/account
make list-ecr-repos REGION=us-west-2 ACCOUNT_ID=123456789012
```

#### Copy images to ECR
```bash
# Copy all images to ECR (default: us-east-2, auto-detect account)
make copy-images-to-ecr

# With custom parameters
make copy-images-to-ecr REGION=us-west-2 ACCOUNT_ID=123456789012
```

The script will:
1. Authenticate with ECR and source registries
2. Create ECR repositories if they don't exist
3. Pull images from public registries
4. Tag and push images to your private ECR
5. Preserve both `latest` and original version tags

#### Update Helm values with ECR references
After copying images to ECR, update the Helm chart values to use your private ECR repositories:
```bash
# Update values.yaml files with ECR image references (default: us-east-2, auto-detect account)
make update-values-with-ecr

# With custom parameters
make update-values-with-ecr REGION=us-west-2 ACCOUNT_ID=123456789012
```

This command will:
1. Parse the ECR image configuration from `tools/ecr-images.conf`
2. Add image repository overrides to the top-level values.yaml file
3. Create backup copies of the original values file
4. Configure the correct ECR URLs for your target region and account

#### Complete ECR setup (recommended)
For a streamlined workflow, use the combined command that copies images and updates values:
```bash
# Copy images to ECR and update Helm values in one command
make setup-ecr-images

# With custom parameters
make setup-ecr-images REGION=us-west-2 ACCOUNT_ID=123456789012
```

### Customizing Images
Edit `tools/ecr-images.conf` to modify which images are copied:
```
# Format: REPO_NAME=SOURCE_IMAGE
aws-efa-k8s-device-plugin=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin:v0.4.4
hyperpod-health-monitoring-agent=763104351884.dkr.ecr.us-west-2.amazonaws.com/sagemaker-hyperpod-health-monitoring-agent:latest
nvidia-k8s-device-plugin=nvcr.io/nvidia/k8s-device-plugin:v0.14.1
mpi-operator=mpioperator/mpi-operator:v0.4.0
```

## Infrastructure Deployment

### Terraform Operations
```bash
# Initialize Terraform
make init

# Plan deployment
make plan

# Apply configuration
make apply

# Destroy infrastructure
make destroy
```

### Helm Operations
```bash
# Lint Helm chart
make helm-lint

# Generate templates
make helm-template
```

## Development

### Submodule Management
```bash
# Update submodules
make submodule-update
```

### Available Commands
```bash
# Show all available commands
make help
```

## Modification Scope

**ONLY modify these paths:**
- `awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/`
- `sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/`

**DO NOT modify:**
- Any other files in the submodules
- Submodule root configurations

## Target Use Cases
- Enterprise ML workloads requiring network isolation
- Regulated industries with strict security requirements
- Air-gapped environments needing HyperPod capabilities

## License
This project is licensed under the MIT License - see the LICENSE file for details.
