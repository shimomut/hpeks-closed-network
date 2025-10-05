# HyperPod EKS Infrastructure Stack

This Terraform stack creates the foundational infrastructure (VPC, Subnets, Route Tables, Security Groups) needed to test HyperPod EKS deployment with existing infrastructure.

## Purpose

This stack allows you to:
1. Create a complete network infrastructure setup
2. Test the main HyperPod deployment with `create_vpc_module = false`, `create_private_subnet_module = false`, and `create_eks_subnets_module = false`
3. Validate that the HyperPod solution works correctly with existing infrastructure

## Infrastructure Created

### VPC and Networking
- **VPC**: Main VPC with DNS support enabled
- **Internet Gateway**: Only created if `closed_network = false`
- **NAT Gateway**: Only created if `closed_network = false`
- **Public Subnets**: Only created if `closed_network = false` (for NAT gateway)

### Subnets
- **HyperPod Private Subnet**: Dedicated subnet for HyperPod instances
- **EKS Private Subnets**: 2 subnets for EKS control plane (multi-AZ)
- **EKS Private Node Subnet**: Dedicated subnet for EKS worker nodes

### Route Tables
- **HyperPod Private Route Table**: Routes for HyperPod subnet
- **EKS Private Route Table**: Routes for EKS control plane subnets
- **EKS Private Node Route Table**: Routes for EKS worker node subnet
- **Public Route Table**: Only created if `closed_network = false`

### Security Group
- **Main Security Group**: Allows all traffic within VPC and HTTPS outbound

## Usage

### Step 1: Deploy Infrastructure Stack

```bash
cd existing-vpc-tf

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### Step 2: Get Infrastructure IDs

After deployment, get the infrastructure IDs:

```bash
# Get all outputs
terraform output

# Get the ready-to-use tfvars snippet
terraform output -raw terraform_tfvars_snippet
```

### Step 3: Configure Main HyperPod Deployment

Copy the output from `terraform_tfvars_snippet` to your main HyperPod deployment `terraform.tfvars` file. The output will look like:

```hcl
# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = false

# Existing infrastructure IDs
existing_vpc_id = "vpc-xxxxxxxxx"
existing_private_subnet_id = "subnet-xxxxxxxxx"
existing_private_route_table_id = "rtb-xxxxxxxxx"
existing_security_group_id = "sg-xxxxxxxxx"
existing_eks_private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
existing_eks_private_node_subnet_id = "subnet-zzzzzzzzz"
existing_eks_private_node_route_table_id = "rtb-yyyyyyyyy"

# Availability zone configuration
availability_zone_id = "use2-az2"
```

### Step 4: Deploy Main HyperPod Stack

Navigate to your main HyperPod deployment directory and deploy with the existing infrastructure:

```bash
cd ../../awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf

# Update terraform.tfvars with the infrastructure IDs from step 3
# Then deploy
terraform init
terraform plan
terraform apply
```

## Configuration Options

### Closed Network Mode

- **`closed_network = true`**: No internet gateway, NAT gateways, or public IPs
- **`closed_network = false`**: Includes internet gateway and NAT gateway for connectivity

### Subnet Configuration

Customize the CIDR blocks in `terraform.tfvars`:

```hcl
vpc_cidr = "10.192.0.0/16"
hyperpod_private_subnet_cidr = "10.1.0.0/16"
eks_private_subnet_cidrs = ["10.192.7.0/24", "10.192.8.0/24"]
eks_private_node_subnet_cidr = "10.192.9.0/24"
```

### Availability Zones

The stack automatically uses the first available AZs in the region. You can control the HyperPod subnet AZ with:

```hcl
hyperpod_availability_zone_index = 1  # 0-based index (0, 1, or 2)
```

## Cleanup

To destroy the infrastructure:

```bash
cd existing-vpc-tf
terraform destroy
```

**Note**: Make sure to destroy the main HyperPod deployment first before destroying this infrastructure stack.

## Validation

The stack includes validation to ensure:
- At least 2 EKS private subnets are created
- Availability zone index is valid (0-2)
- Proper subnet tagging for EKS integration

## Next Steps

After deploying this infrastructure stack:
1. Use the output values in your main HyperPod deployment
2. Verify that the main deployment works with `create_vpc_module = false`
3. Test the complete HyperPod functionality in the closed network environment