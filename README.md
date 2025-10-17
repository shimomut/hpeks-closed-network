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
│       ├── terraform.tfvars                    # Full stack deployment config
│       └── terraform-with-existing-vpc.tfvars # Two-phase deployment config
├── existing-vpc-tf/        # Infrastructure stack for two-phase deployment
│   ├── main.tf            # VPC, subnets, route tables
│   ├── variables.tf       # Infrastructure variables
│   ├── outputs.tf         # Infrastructure outputs
│   └── terraform.tfvars   # Infrastructure configuration
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

#### Configuration File Guide

| File | Purpose | Deployment Type |
|------|---------|-----------------|
| `awsome-distributed-training/.../terraform.tfvars` | Full stack deployment | Single-phase |
| `awsome-distributed-training/.../terraform-with-existing-vpc.tfvars` | Main stack with existing VPC | Two-phase (Phase 2) |
| `existing-vpc-tf/terraform.tfvars` | Infrastructure stack only | Two-phase (Phase 1) |

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
```

## Deployment Options

This project supports two deployment approaches to accommodate different infrastructure requirements:

### Option 1: Full Stack Deployment (Single Phase)
Creates all infrastructure components (VPC, subnets, security groups, EKS cluster, HyperPod cluster) in a single deployment.

### Option 2: Two-Phase Deployment (Existing VPC)

Separates infrastructure creation into two phases:
1. **Phase 1**: Deploy foundational infrastructure (VPC, subnets, route tables)
2. **Phase 2**: Deploy HyperPod cluster using the existing infrastructure

#### Benefits of Two-Phase Deployment:

This option is useful when your corporate IT policy requires special settings for network configuration, or when you need to validate infrastructure separately from compute resources.

## Quick Start Guide

### Full Stack Deployment (Option 1)

**1. Configure Your Deployment:**
```bash
# Edit the full stack configuration file
vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
```

**2. Prepare Container Images (Closed Network Only):**
```bash
# Copy all required images to ECR and update Helm values
make setup-ecr-images REGION=us-east-2 ACCOUNT_ID=auto
```

**3. Deploy Infrastructure:**
```bash
# Initialize and deploy full stack
make init
make plan-full-stack
make apply-full-stack
```

### Two-Phase Deployment (Option 2) - Recommended for Testing

**Phase 1: Deploy Infrastructure Stack**

1. **Configure Infrastructure Stack:**
```bash
# Edit infrastructure-only configuration
vim existing-vpc-tf/terraform.tfvars
```

Key infrastructure parameters:
```hcl
resource_name_prefix = "hpeks-infra-test"
aws_region           = "us-east-2"
closed_network       = true                    # No internet gateway/NAT
vpc_cidr             = "10.192.0.0/16"        # Main VPC CIDR
hyperpod_private_subnet_cidr = "10.1.0.0/16"  # Large subnet for HyperPod
eks_private_subnet_cidrs = ["10.192.7.0/24", "10.192.8.0/24"]  # EKS control plane
eks_private_node_subnet_cidr = "10.192.9.0/24"  # EKS worker nodes
```

2. **Deploy Infrastructure Stack:**
```bash
# Deploy VPC, subnets, and route tables
make deploy-infra-stack
```

3. **Get Infrastructure Configuration:**
```bash
# Extract infrastructure IDs for main deployment
make infra-tfvars
```

**Phase 2: Deploy HyperPod Cluster**

4. **Configure Main Stack:**
```bash
# Edit the existing VPC configuration file
vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform-with-existing-vpc.tfvars
```

The infrastructure stack automatically provides the required configuration. Key settings:
```hcl
# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs (auto-populated from Phase 1)
existing_vpc_id = "vpc-xxxxxxxxx"
existing_private_subnet_id = "subnet-xxxxxxxxx"
existing_eks_private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
# ... other infrastructure IDs
```

5. **Prepare Container Images (Closed Network Only):**
```bash
# Copy images to ECR and update Helm values
make setup-ecr-images REGION=us-east-2 ACCOUNT_ID=auto
```

6. **Deploy HyperPod Cluster:**
```bash
# Deploy cluster using existing infrastructure
make deploy-cluster-existing-vpc
```

**Alternative: Automated Two-Phase Deployment**
```bash
# Fully automated deployment (infrastructure + cluster)
make deploy-e2e-existing-vpc
```

### Verify Deployment
```bash
# Check infrastructure stack status
make infra-output

# List Helm releases
make helm-list-releases

# Check EKS cluster status
aws eks describe-cluster --name <your-cluster-name> --region <your-region>

# Check HyperPod cluster status
aws sagemaker describe-cluster --cluster-name <hyperpod-cluster-name>
```

## Configuration Guide

### Configuration Files

This project uses different configuration files depending on your deployment approach:

**Full Stack Deployment:**
```
awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
```

**Two-Phase Deployment:**
- Infrastructure Stack: `existing-vpc-tf/terraform.tfvars`
- Main Stack: `awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform-with-existing-vpc.tfvars`

### Infrastructure Stack Configuration (Two-Phase Deployment)

The infrastructure stack (`existing-vpc-tf/terraform.tfvars`) creates the foundational networking components:

**Basic Infrastructure Settings:**
```hcl
resource_name_prefix = "hpeks-infra-test"  # Unique prefix for resources
aws_region           = "us-east-2"         # Target AWS region
closed_network       = true                # No internet gateway/NAT gateways
```

**Network Configuration:**
```hcl
vpc_cidr = "10.192.0.0/16"                 # Main VPC CIDR block

# HyperPod subnet (large /16 for many instances)
hyperpod_private_subnet_cidr = "10.1.0.0/16"
hyperpod_availability_zone_index = 1       # AZ index (0-2)

# EKS control plane subnets (multi-AZ for HA)
eks_private_subnet_cidrs = ["10.192.7.0/24", "10.192.8.0/24"]

# EKS worker node subnet
eks_private_node_subnet_cidr = "10.192.9.0/24"

# EKS cluster name (for subnet tagging)
eks_cluster_name = "hpeks-test-cluster"
```

### Main Stack Configuration

#### Key Configuration Parameters

**Basic Settings:**
```hcl
resource_name_prefix = "sagemaker-hpeks-closed-8"  # Unique prefix for resources
aws_region           = "us-east-2"                 # Target AWS region
closed_network       = true                        # Enable closed network mode
```

**Module Control (Two-Phase Deployment):**
```hcl
# Use existing infrastructure from Phase 1
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true  # Create security groups only
```

**Existing Infrastructure IDs (Auto-populated from Phase 1):**
```hcl
existing_vpc_id = "vpc-xxxxxxxxx"
existing_private_subnet_id = "subnet-xxxxxxxxx"
existing_private_route_table_id = "rtb-xxxxxxxxx"
existing_eks_private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
existing_eks_private_node_subnet_id = "subnet-zzzzzzzzz"
existing_eks_private_node_route_table_id = "rtb-yyyyyyyyy"
availability_zone_id = "us-east-2b"
```

**EKS Configuration:**
```hcl
kubernetes_version           = "1.32"                           # EKS version
eks_cluster_name             = "eks-closed-8"                   # Cluster name
eks_availability_zones       = ["use2-az1", "use2-az2"]        # AZ configuration
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

### Available Make Commands

**Generic Terraform Operations:**
```bash
# Initialize Terraform
make init

# Plan deployment (defaults to terraform.tfvars)
make plan

# Plan with specific configuration file
make plan TFVARS=terraform-with-existing-vpc.tfvars

# Apply configuration (defaults to terraform.tfvars)
make apply

# Apply with specific configuration file
make apply TFVARS=terraform-with-existing-vpc.tfvars

# Destroy infrastructure
make destroy TFVARS=terraform-with-existing-vpc.tfvars
```

**Deployment-Specific Commands:**
```bash
# Full Stack Deployment
make plan-full-stack          # Plan full stack (creates new VPC)
make apply-full-stack         # Deploy full stack

# Two-Phase Deployment
make plan-existing-vpc        # Plan with existing VPC
make apply-existing-vpc       # Deploy with existing VPC

# Infrastructure Stack Operations
make infra-init              # Initialize infrastructure stack
make infra-plan              # Plan infrastructure stack
make infra-apply             # Deploy infrastructure stack
make infra-destroy           # Destroy infrastructure stack
make infra-output            # Show infrastructure outputs
make infra-tfvars            # Generate config for main stack

# Combined Workflows
make deploy-infra-stack      # Deploy complete infrastructure stack
make deploy-cluster-existing-vpc  # Deploy cluster with existing VPC
make deploy-e2e-existing-vpc # End-to-end two-phase deployment
make destroy-all             # Destroy cluster + infrastructure (correct order)
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

## Deployment Workflows

### Full Stack Deployment Workflow

1. **Configure your deployment:**
   ```bash
   # Edit full stack configuration
   vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars
   ```

2. **Prepare container images (closed network only):**
   ```bash
   # Copy images to ECR and update Helm values
   make setup-ecr-images
   ```

3. **Deploy infrastructure:**
   ```bash
   # Initialize and deploy full stack
   make init
   make plan-full-stack
   make apply-full-stack
   ```

### Two-Phase Deployment Workflow

**Phase 1: Infrastructure Stack**
1. **Configure infrastructure:**
   ```bash
   # Edit infrastructure stack configuration
   vim existing-vpc-tf/terraform.tfvars
   ```

2. **Deploy infrastructure:**
   ```bash
   # Deploy VPC, subnets, route tables
   make deploy-infra-stack
   ```

3. **Extract configuration:**
   ```bash
   # Get infrastructure IDs for main stack
   make infra-tfvars
   
   # Copy output to main stack configuration file
   # (This step is automated in deploy-cluster-existing-vpc)
   ```

**Phase 2: HyperPod Cluster**
4. **Configure main stack:**
   ```bash
   # Edit existing VPC configuration (infrastructure IDs auto-populated)
   vim awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform-with-existing-vpc.tfvars
   ```

5. **Prepare container images (closed network only):**
   ```bash
   # Copy images to ECR and update Helm values
   make setup-ecr-images
   ```

6. **Deploy HyperPod cluster:**
   ```bash
   # Deploy cluster using existing infrastructure
   make deploy-cluster-existing-vpc
   ```

**Alternative: Automated Two-Phase Deployment**
```bash
# Configure both phases, then run automated deployment
make deploy-e2e-existing-vpc
```

### Verification Steps
```bash
# Check infrastructure stack (two-phase deployment)
make infra-output

# Check Helm releases
make helm-list-releases

# Verify EKS cluster
aws eks describe-cluster --name <cluster-name> --region <region>

# Check HyperPod cluster status
aws sagemaker describe-cluster --cluster-name <hyperpod-cluster-name>

# Verify VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id>
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
```

### Cleanup Workflows

**Full Stack Cleanup:**
```bash
make destroy TFVARS=terraform.tfvars
```

**Two-Phase Cleanup (Correct Order):**
```bash
# Destroy in correct order (cluster first, then infrastructure)
make destroy-all

# Or manual cleanup:
make destroy TFVARS=terraform-with-existing-vpc.tfvars  # Destroy cluster first
make infra-destroy                                      # Destroy infrastructure second
```

### Troubleshooting Deployment Issues

**Common Issues and Solutions:**

1. **Infrastructure Stack Issues (Two-Phase Deployment):**
   ```bash
   # Check infrastructure stack status
   make infra-output
   
   # Verify VPC and subnets were created
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=hpeks-infra-test-vpc"
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=<vpc-id>"
   
   # Refresh infrastructure state if needed
   cd existing-vpc-tf && terraform refresh
   ```

2. **Configuration Mismatch (Two-Phase Deployment):**
   ```bash
   # Regenerate configuration from infrastructure stack
   make infra-tfvars
   
   # Verify infrastructure IDs in main stack configuration
   grep "existing_" awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform-with-existing-vpc.tfvars
   ```

3. **CIDR Block Conflicts:**
   ```bash
   # Check for CIDR overlaps
   aws ec2 describe-vpcs --vpc-ids <vpc-id> --query 'Vpcs[0].CidrBlockAssociationSet'
   
   # Verify HyperPod subnet CIDR (should be 10.1.0.0/16)
   aws ec2 describe-subnets --subnet-ids <hyperpod-subnet-id> --query 'Subnets[0].CidrBlock'
   ```

4. **ECR Authentication Errors:**
   ```bash
   # Re-authenticate with ECR
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account>.dkr.ecr.<region>.amazonaws.com
   ```

5. **Terraform State Issues:**
   ```bash
   # Refresh Terraform state for main stack
   cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf
   terraform refresh -var-file="terraform-with-existing-vpc.tfvars"
   
   # Refresh infrastructure stack state
   cd existing-vpc-tf && terraform refresh
   ```

6. **Helm Chart Dependencies:**
   ```bash
   # Update chart dependencies
   helm dependency update sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/
   ```

7. **VPC Endpoint Connectivity:**
   - Ensure VPC endpoints are created for required AWS services
   - Verify security group rules allow traffic to VPC endpoints
   - Check route table configurations for private subnets
   - Validate DNS resolution for VPC endpoints

8. **Deployment Order Issues:**
   ```bash
   # Always destroy in correct order (cluster first, then infrastructure)
   make destroy-all
   
   # Or manually:
   make destroy TFVARS=terraform-with-existing-vpc.tfvars  # Cluster first
   make infra-destroy                                      # Infrastructure second
   ```

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

### S3 Bucket Configuration for Lifecycle Scripts

HyperPod clusters can use S3 buckets to store lifecycle scripts that run during instance startup. You can configure the deployment to use an existing KMS-encrypted S3 bucket instead of creating a new one.

**Using an Existing KMS-Encrypted S3 Bucket:**
```hcl
# Disable S3 bucket creation modules
create_s3_bucket_module = false
create_lifecycle_script_module = false

# Specify existing S3 bucket and KMS key
existing_s3_bucket_name = "sagemaker-cluster-kms-842413447717-us-east-2"
kms_key_arn = "arn:aws:kms:us-east-2:842413447717:key/32ecc6cb-75f0-4764-b4dd-d0a1ffb0f9ad"
```

**Configuration Parameters:**
- `create_s3_bucket_module = false`: Disables creation of a new S3 bucket
- `create_lifecycle_script_module = false`: Disables upload of default lifecycle scripts
- `existing_s3_bucket_name`: Name of your existing S3 bucket containing lifecycle scripts
- `kms_key_arn`: ARN of the KMS key used to encrypt the S3 bucket


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
