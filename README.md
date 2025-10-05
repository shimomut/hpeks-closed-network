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
- Terraform installed (version 1.0+)
- Helm installed (version 3.0+)
- Git with submodule support
- Python 3 with `ruamel.yaml` package (for ECR values update script)

### Initial Setup
```bash
# Clone repository with submodules
git clone --recursive <repository-url>
cd <repository-directory>

# Install Python dependencies for ECR values update script
python3 -m pip install ruamel.yaml

# Initialize development environment
make dev-setup
```

## Quick Start Guide

### 1. Configure Your Deployment
Edit the Terraform configuration file to match your environment:
```bash
# Edit the main configuration file
vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
```

Key configuration parameters:
- `resource_name_prefix`: Unique prefix for all resources
- `aws_region`: Target AWS region (e.g., "us-east-2")
- `closed_network`: Set to `true` for air-gapped deployments
- `vpc_cidr`: VPC CIDR block (e.g., "10.192.0.0/16")
- `kubernetes_version`: EKS cluster version (e.g., "1.32")
- `instance_groups`: Define your HyperPod compute instances

### 2. Prepare Container Images (Closed Network Only)
For closed network deployments, copy required container images to your private ECR:
```bash
# Copy all required images to ECR and update Helm values
make setup-ecr-images

# Or with custom region/account
make setup-ecr-images REGION=us-west-2 ACCOUNT_ID=123456789012
```

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
make init

# Review deployment plan
make plan

# Deploy the infrastructure
make apply
```

### 4. Verify Deployment
```bash
# List Helm releases
make helm-list-releases

# Check EKS cluster status
aws eks describe-cluster --name <your-cluster-name> --region <your-region>
```

## Configuration Guide

### Terraform Configuration
The main configuration file is located at:
```
awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
```

#### Key Configuration Parameters

**Basic Settings:**
```hcl
resource_name_prefix = "sagemaker-hpeks-closed-8"  # Unique prefix for resources
aws_region           = "us-east-2"                 # Target AWS region
closed_network       = true                        # Enable closed network mode
```

**Network Configuration:**
```hcl
vpc_cidr             = "10.192.0.0/16"    # VPC CIDR block
public_subnet_1_cidr = "10.192.10.0/24"   # Public subnet 1
public_subnet_2_cidr = "10.192.11.0/24"   # Public subnet 2
private_subnet_cidr  = "10.1.0.0/16"      # Private subnet for HyperPod
```

**EKS Configuration:**
```hcl
kubernetes_version           = "1.32"                           # EKS version
eks_cluster_name             = "eks-closed-8"                   # Cluster name
eks_availability_zones       = ["use2-az1", "use2-az2"]        # AZ configuration
eks_private_subnet_cidrs     = ["10.192.7.0/24", "10.192.8.0/24"]  # EKS subnets
```

**HyperPod Instance Groups:**
```hcl
instance_groups = {
  instance-group-1 = {
    instance_type             = "ml.g5.8xlarge"  # Instance type
    instance_count            = 2                # Number of instances
    ebs_volume_size_in_gb     = 100             # Storage size
    threads_per_core          = 2               # CPU threading
    enable_stress_check       = false           # Health checks
    enable_connectivity_check = false
    lifecycle_script          = "on_create.sh"  # Startup script
  }
}
```

### Container Image Management

For closed network deployments, you'll need to copy required container images to your private ECR repositories.

#### Required Images
- `aws-efa-k8s-device-plugin` - AWS EFA Kubernetes Device Plugin
- `hyperpod-health-monitoring-agent` - HyperPod Health Monitoring Agent
- `nvidia-k8s-device-plugin` - NVIDIA Kubernetes Device Plugin
- `mpi-operator` - MPI Operator for distributed training
- `kubeflow-training-operator` - Kubeflow Training Operator for PyTorch, TensorFlow, etc.

#### ECR Operations

**Preview ECR repositories:**
```bash
# List repositories that will be created (default: us-east-2)
make list-ecr-repos

# With custom region/account
make list-ecr-repos REGION=us-west-2 ACCOUNT_ID=123456789012
```

**Copy images to ECR:**
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

**Update Helm values with ECR references:**
```bash
# Update values.yaml files with ECR image references (default: us-east-2, auto-detect account)
make update-values-with-ecr

# With custom parameters
make update-values-with-ecr REGION=us-west-2 ACCOUNT_ID=123456789012
```

**Complete ECR setup (recommended):**
```bash
# Copy images to ECR and update Helm values in one command
make setup-ecr-images

# With custom parameters
make setup-ecr-images REGION=us-west-2 ACCOUNT_ID=123456789012
```

#### Customizing Images
Edit `tools/ecr-images.conf` to modify which images are copied:
```
# Format: REPO_NAME=SOURCE_IMAGE
aws-efa-k8s-device-plugin=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin:v0.5.6
hyperpod-health-monitoring-agent=905418368575.dkr.ecr.us-west-2.amazonaws.com/hyperpod-health-monitoring-agent:1.0.819.0_1.0.267.0
nvidia-k8s-device-plugin=nvcr.io/nvidia/k8s-device-plugin:v0.16.1
mpi-operator=mpioperator/mpi-operator:0.5
kubeflow-training-operator=kubeflow/training-operator:v1-855e096
```

## Infrastructure Deployment

### Terraform Operations
```bash
# Initialize Terraform
make init

# Plan deployment (review changes before applying)
make plan

# Apply configuration (deploy infrastructure)
make apply

# Destroy infrastructure (cleanup)
make destroy
```

### Helm Operations
```bash
# Lint Helm chart (validate syntax)
make helm-lint

# Generate templates (preview Kubernetes manifests)
make helm-template

# Install Helm chart
make helm-install

# Install with custom parameters
make helm-install RELEASE=my-hyperpod NAMESPACE=hyperpod-system

# List installed releases
make helm-list-releases

# Uninstall release
make helm-uninstall RELEASE=hyperpod-dependencies
```

## Deployment Workflow

### Complete Deployment Process
1. **Configure your deployment:**
   ```bash
   # Edit terraform.tfvars with your specific settings
   vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
   ```

2. **Prepare container images (closed network only):**
   ```bash
   # Copy images to ECR and update Helm values
   make setup-ecr-images
   ```

3. **Deploy infrastructure:**
   ```bash
   # Initialize and deploy
   make init
   make plan
   make apply
   ```

4. **Verify deployment:**
   ```bash
   # Check Helm releases
   make helm-list-releases
   
   # Verify EKS cluster
   aws eks describe-cluster --name <cluster-name> --region <region>
   
   # Check HyperPod cluster status
   aws sagemaker describe-cluster --cluster-name <hyperpod-cluster-name>
   ```

### Troubleshooting Deployment Issues

**Common Issues and Solutions:**

1. **ECR Authentication Errors:**
   ```bash
   # Re-authenticate with ECR
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
   ```

2. **Terraform State Issues:**
   ```bash
   # Refresh Terraform state
   cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf
   terraform refresh
   ```

3. **Helm Chart Dependencies:**
   ```bash
   # Update chart dependencies
   helm dependency update sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/
   ```

4. **VPC Endpoint Connectivity:**
   - Ensure VPC endpoints are created for required AWS services
   - Verify security group rules allow traffic to VPC endpoints
   - Check route table configurations for private subnets

## Advanced Usage

### Custom Instance Groups
Define multiple instance groups for different workload types:
```hcl
instance_groups = {
  training-nodes = {
    instance_type             = "ml.p4d.24xlarge"
    instance_count            = 4
    ebs_volume_size_in_gb     = 500
    threads_per_core          = 2
    enable_stress_check       = true
    enable_connectivity_check = true
    lifecycle_script          = "training_setup.sh"
  }
  inference-nodes = {
    instance_type             = "ml.g5.12xlarge"
    instance_count            = 2
    ebs_volume_size_in_gb     = 200
    threads_per_core          = 1
    enable_stress_check       = false
    enable_connectivity_check = false
    lifecycle_script          = "inference_setup.sh"
  }
}
```

### Network Isolation Levels
Configure different levels of network isolation:

**Fully Closed Network (Air-gapped):**
```hcl
closed_network = true
create_vpc_endpoints_module = true  # Required for AWS service access
```

**Partially Closed Network (Outbound only through NAT):**
```hcl
closed_network = false
# Configure NAT gateways for outbound internet access
```



## Development and Customization

### Submodule Management
```bash
# Update submodules to latest versions
make submodule-update

# Check submodule status
git submodule status

# Update specific submodule
git submodule update --remote awsome-distributed-training
```

### Available Commands
```bash
# Show all available commands with descriptions
make help
```

### Customization Guidelines

**ONLY modify these paths:**
- `awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/`
- `sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/`

**DO NOT modify:**
- Any other files in the submodules
- Submodule root configurations
- Core infrastructure components outside the specified paths

### Testing Changes
```bash
# Validate Terraform configuration
make plan

# Test Helm chart syntax
make helm-lint

# Generate and review Kubernetes manifests
make helm-template
```

## Security Considerations

### Closed Network Architecture
- No internet gateway or NAT gateways in fully closed mode
- All AWS service access through VPC endpoints
- Private subnets only for compute resources
- Security groups restrict traffic to necessary ports only

### IAM Permissions
Required IAM permissions for deployment:
- EKS cluster creation and management
- SageMaker HyperPod cluster operations
- ECR repository access
- VPC and networking resource management
- S3 bucket operations for lifecycle scripts

### Data Protection
- All data remains within your VPC
- Encryption in transit and at rest
- No data egress to public internet in closed network mode

## Target Use Cases
- **Enterprise ML workloads** requiring network isolation
- **Regulated industries** with strict security requirements (healthcare, finance, government)
- **Air-gapped environments** needing HyperPod capabilities
- **Multi-tenant environments** with strict data isolation requirements
- **High-performance computing** workloads requiring dedicated networking

## Support and Troubleshooting

### Common Issues
1. **VPC Endpoint Connectivity**: Ensure all required VPC endpoints are created
2. **Security Group Rules**: Verify inbound/outbound rules for cluster communication
3. **Subnet Configuration**: Check CIDR blocks don't overlap and have sufficient IP addresses
4. **Instance Limits**: Verify AWS service limits for chosen instance types

### Getting Help
- Review Terraform plan output for configuration issues
- Check CloudWatch logs for deployment errors
- Use AWS CLI to verify resource states
- Consult AWS documentation for service-specific requirements

## License
This project is licensed under the MIT License - see the LICENSE file for details.
