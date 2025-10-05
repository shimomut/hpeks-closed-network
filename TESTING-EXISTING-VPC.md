# Testing Guide: Deploying HyperPod EKS with Existing VPC

This document provides a comprehensive testing guide for deploying Amazon SageMaker HyperPod on Amazon EKS using an existing VPC infrastructure. The deployment is split into two phases to demonstrate modular infrastructure management.

## Overview

This testing scenario demonstrates:
1. **Phase 1**: Creating VPC, subnets (including EKS subnets), route tables, and core network resources as a separate stack
2. **Phase 2**: Creating EKS cluster, HyperPod cluster, S3 bucket, IAM roles, security groups, and remaining cluster-related resources using the existing VPC and EKS subnets

This approach is common in enterprise environments where network infrastructure is managed separately from application infrastructure.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker installed and running
- Terraform installed (version 1.0+)
- Helm installed (version 3.0+)
- Git with submodule support
- Python 3 with `ruamel.yaml` package (for ECR values update script)
- Sufficient AWS service limits for chosen instance types

## Phase 1: Network Infrastructure Stack

### Step 1.1: Prepare Network Configuration

Create a dedicated configuration file for the network stack:

```bash
# Create a network-specific configuration
cp awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/terraform.tfvars \
   awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf/network.tfvars
```

Edit `network.tfvars` to create only network resources:

```hcl
# Basic Settings
resource_name_prefix = "hpeks-network-test"
aws_region           = "us-east-2"
closed_network       = true

# Network Configuration
vpc_cidr             = "10.192.0.0/16"
public_subnet_1_cidr = "10.192.10.0/24"
public_subnet_2_cidr = "10.192.11.0/24"
private_subnet_cidr  = "10.1.0.0/16"
availability_zone_id = "use2-az1"

# EKS Network Configuration
eks_availability_zones       = ["use2-az1", "use2-az2"]
eks_private_subnet_cidrs     = ["10.192.7.0/28", "10.192.8.0/28"]
eks_private_node_subnet_cidr = "10.192.9.0/24"

# Module Control - ONLY CREATE NETWORK RESOURCES
create_vpc_module            = true
create_private_subnet_module = true
create_eks_subnets_module    = true
create_eks_module           = false
create_security_group_module = false
create_s3_bucket_module     = false
create_sagemaker_iam_role_module = false
create_lifecycle_script_module = false
create_vpc_endpoints_module = false
create_helm_chart_module    = false
create_hyperpod_module      = false

# Placeholder values for unused modules
eks_cluster_name         = "placeholder"
hyperpod_cluster_name    = "placeholder"
kubernetes_version       = "1.32"
instance_groups = {}
```

### Step 1.2: Deploy Network Stack

```bash
# Initialize Terraform
cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf
terraform init

# Plan network deployment
terraform plan -var-file="network.tfvars" -out=network.tfplan

# Review the plan - should only show VPC, subnets, route tables, NAT gateways
terraform show network.tfplan

# Apply network configuration
terraform apply network.tfplan
```

### Step 1.3: Capture Network Outputs

After successful deployment, capture the network resource IDs:

```bash
# Get VPC ID
VPC_ID=$(terraform output -raw vpc_id)
echo "VPC ID: $VPC_ID"

# Get Private Subnet ID
PRIVATE_SUBNET_ID=$(terraform output -raw private_subnet_id)
echo "Private Subnet ID: $PRIVATE_SUBNET_ID"

# Get NAT Gateway ID (if not in closed network mode)
if terraform output nat_gateway_id >/dev/null 2>&1; then
    NAT_GATEWAY_ID=$(terraform output -raw nat_gateway_id)
    echo "NAT Gateway ID: $NAT_GATEWAY_ID"
fi

# Get Private Route Table ID
PRIVATE_ROUTE_TABLE_ID=$(terraform output -raw private_route_table_id)
echo "Private Route Table ID: $PRIVATE_ROUTE_TABLE_ID"

# Get EKS Subnet IDs
EKS_PRIVATE_SUBNET_IDS=$(terraform output -json eks_private_subnet_ids | jq -r '.[]' | tr '\n' ',' | sed 's/,$//')
echo "EKS Private Subnet IDs: $EKS_PRIVATE_SUBNET_IDS"

EKS_PRIVATE_NODE_SUBNET_ID=$(terraform output -raw eks_private_node_subnet_id)
echo "EKS Private Node Subnet ID: $EKS_PRIVATE_NODE_SUBNET_ID"

EKS_PRIVATE_NODE_ROUTE_TABLE_ID=$(terraform output -raw eks_private_node_route_table_id)
echo "EKS Private Node Route Table ID: $EKS_PRIVATE_NODE_ROUTE_TABLE_ID"

# Save outputs to file for Phase 2
cat > ../network-outputs.env << EOF
export VPC_ID="$VPC_ID"
export PRIVATE_SUBNET_ID="$PRIVATE_SUBNET_ID"
export NAT_GATEWAY_ID="$NAT_GATEWAY_ID"
export PRIVATE_ROUTE_TABLE_ID="$PRIVATE_ROUTE_TABLE_ID"
export EKS_PRIVATE_SUBNET_IDS="$EKS_PRIVATE_SUBNET_IDS"
export EKS_PRIVATE_NODE_SUBNET_ID="$EKS_PRIVATE_NODE_SUBNET_ID"
export EKS_PRIVATE_NODE_ROUTE_TABLE_ID="$EKS_PRIVATE_NODE_ROUTE_TABLE_ID"
EOF

echo "Network outputs saved to network-outputs.env"
```

### Step 1.4: Verify Network Infrastructure

```bash
# Verify VPC creation
aws ec2 describe-vpcs --vpc-ids $VPC_ID --region us-east-2

# Verify subnets (including EKS subnets)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-2

# Verify EKS subnets specifically
IFS=',' read -ra SUBNET_ARRAY <<< "$EKS_PRIVATE_SUBNET_IDS"
for subnet in "${SUBNET_ARRAY[@]}"; do
    echo "Verifying EKS subnet: $subnet"
    aws ec2 describe-subnets --subnet-ids "$subnet" --region us-east-2
done

aws ec2 describe-subnets --subnet-ids "$EKS_PRIVATE_NODE_SUBNET_ID" --region us-east-2

# Verify route tables (including EKS route tables)
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-2

# Check NAT Gateway (if applicable)
if [ -n "$NAT_GATEWAY_ID" ]; then
    aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --region us-east-2
fi
```

## Phase 2: Cluster Infrastructure Stack

### Step 2.1: Prepare Cluster Configuration

Create a configuration file for the cluster stack:

```bash
# Load network outputs
source ../network-outputs.env

# Create cluster-specific configuration
cp terraform.tfvars cluster.tfvars
```

Edit `cluster.tfvars` to use existing network resources:

```hcl
# Basic Settings
resource_name_prefix = "hpeks-cluster-test"
aws_region           = "us-east-2"
closed_network       = true

# Use Existing Network Resources
create_vpc_module            = false
create_private_subnet_module = false
create_eks_subnets_module    = false
existing_vpc_id              = "vpc-xxxxxxxxx"  # Replace with actual VPC ID
existing_private_subnet_id   = "subnet-xxxxxxxxx"  # Replace with actual subnet ID
existing_nat_gateway_id      = "nat-xxxxxxxxx"  # Replace with actual NAT Gateway ID (if applicable)
existing_private_route_table_id = "rtb-xxxxxxxxx"  # Replace with actual route table ID
existing_eks_private_subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]  # Replace with actual EKS subnet IDs
existing_eks_private_node_subnet_id = "subnet-zzzzzzzzz"  # Replace with actual EKS node subnet ID
existing_eks_private_node_route_table_id = "rtb-yyyyyyyyy"  # Replace with actual EKS node route table ID

# Network Configuration (for reference)
vpc_cidr             = "10.192.0.0/16"
private_subnet_cidr  = "10.1.0.0/16"
availability_zone_id = "use2-az1"

# EKS Configuration
create_eks_module           = true
eks_cluster_name            = "hpeks-cluster-test"
kubernetes_version          = "1.32"
eks_availability_zones      = ["use2-az1", "use2-az2"]
eks_private_subnet_cidrs    = ["10.192.7.0/28", "10.192.8.0/28"]
eks_private_node_subnet_cidr = "10.192.9.0/24"

# Cluster Resources
create_security_group_module    = true
create_s3_bucket_module         = true
create_sagemaker_iam_role_module = true
create_lifecycle_script_module  = true
create_vpc_endpoints_module     = true
create_helm_chart_module        = true
create_hyperpod_module          = true

# HyperPod Configuration
hyperpod_cluster_name = "hpeks-cluster-test"
node_recovery         = "Automatic"
node_provisioning_mode = "OnDemand"

# Instance Groups
instance_groups = {
  test-group = {
    instance_type             = "ml.g5.2xlarge"
    instance_count            = 1
    ebs_volume_size_in_gb     = 100
    threads_per_core          = 2
    enable_stress_check       = false
    enable_connectivity_check = false
    lifecycle_script          = "on_create.sh"
  }
}

# Helm Configuration
helm_repo_base_path = "../../sagemaker-hyperpod-cli"
helm_repo_path      = "helm_chart/HyperPodHelmChart"
namespace           = "kube-system"
helm_release_name   = "hyperpod-dependencies"
```

### Step 2.2: Update Configuration with Actual Resource IDs

```bash
# Update cluster.tfvars with actual resource IDs
sed -i "s/existing_vpc_id.*=.*/existing_vpc_id = \"$VPC_ID\"/" cluster.tfvars
sed -i "s/existing_private_subnet_id.*=.*/existing_private_subnet_id = \"$PRIVATE_SUBNET_ID\"/" cluster.tfvars
sed -i "s/existing_private_route_table_id.*=.*/existing_private_route_table_id = \"$PRIVATE_ROUTE_TABLE_ID\"/" cluster.tfvars

# Update EKS subnet configurations
IFS=',' read -ra SUBNET_ARRAY <<< "$EKS_PRIVATE_SUBNET_IDS"
SUBNET_LIST=$(printf '"%s",' "${SUBNET_ARRAY[@]}")
SUBNET_LIST="[${SUBNET_LIST%,}]"
sed -i "s/existing_eks_private_subnet_ids.*=.*/existing_eks_private_subnet_ids = $SUBNET_LIST/" cluster.tfvars
sed -i "s/existing_eks_private_node_subnet_id.*=.*/existing_eks_private_node_subnet_id = \"$EKS_PRIVATE_NODE_SUBNET_ID\"/" cluster.tfvars
sed -i "s/existing_eks_private_node_route_table_id.*=.*/existing_eks_private_node_route_table_id = \"$EKS_PRIVATE_NODE_ROUTE_TABLE_ID\"/" cluster.tfvars

if [ -n "$NAT_GATEWAY_ID" ]; then
    sed -i "s/existing_nat_gateway_id.*=.*/existing_nat_gateway_id = \"$NAT_GATEWAY_ID\"/" cluster.tfvars
fi

echo "Updated cluster.tfvars with actual resource IDs"
```

### Step 2.3: Prepare Container Images (Closed Network)

For closed network deployments, prepare container images:

```bash
# Return to project root
cd ../../../../..

# Copy images to ECR and update Helm values
make setup-ecr-images REGION=us-east-2

# Verify ECR repositories were created
make list-ecr-repos REGION=us-east-2
```

### Step 2.4: Deploy Cluster Stack

```bash
# Return to Terraform directory
cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf

# Plan cluster deployment
terraform plan -var-file="cluster.tfvars" -out=cluster.tfplan

# Review the plan - should show EKS, HyperPod, S3, IAM, Security Groups, VPC Endpoints
terraform show cluster.tfplan

# Apply cluster configuration
terraform apply cluster.tfplan
```

### Step 2.5: Verify Cluster Deployment

```bash
# Get cluster outputs
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
HYPERPOD_CLUSTER_NAME=$(terraform output -raw hyperpod_cluster_name)
S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)

echo "EKS Cluster: $EKS_CLUSTER_NAME"
echo "HyperPod Cluster: $HYPERPOD_CLUSTER_NAME"
echo "S3 Bucket: $S3_BUCKET_NAME"

# Verify EKS cluster
aws eks describe-cluster --name $EKS_CLUSTER_NAME --region us-east-2

# Verify HyperPod cluster
aws sagemaker describe-cluster --cluster-name $HYPERPOD_CLUSTER_NAME --region us-east-2

# Verify S3 bucket
aws s3 ls s3://$S3_BUCKET_NAME --region us-east-2

# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-2
```

## Testing Scenarios

### Test 1: Basic Connectivity

```bash
# Update kubeconfig
aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region us-east-2

# Check EKS nodes
kubectl get nodes

# Check HyperPod-related pods
kubectl get pods -n kube-system | grep -E "(aws-efa|nvidia|mpi|health)"

# Verify Helm releases
cd ../../../../..
make helm-list-releases NAMESPACE=kube-system
```

### Test 2: Network Isolation (Closed Network)

```bash
# Test VPC endpoint connectivity from EKS nodes
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup s3.us-east-2.amazonaws.com

# Verify no internet access (should fail)
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup google.com

# Check security group rules
SECURITY_GROUP_ID=$(terraform output -raw security_group_id)
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --region us-east-2
```

### Test 3: HyperPod Instance Health

```bash
# Check HyperPod cluster status
aws sagemaker describe-cluster --cluster-name $HYPERPOD_CLUSTER_NAME --region us-east-2

# List cluster instances
aws sagemaker list-cluster-nodes --cluster-name $HYPERPOD_CLUSTER_NAME --region us-east-2

# Check instance health (if instances are running)
aws sagemaker describe-cluster-node --cluster-name $HYPERPOD_CLUSTER_NAME --node-id <node-id> --region us-east-2
```

### Test 4: Resource Dependencies

```bash
# Verify EKS can access S3 bucket
kubectl run aws-cli --image=amazon/aws-cli --rm -it --restart=Never -- s3 ls s3://$S3_BUCKET_NAME

# Check IAM role permissions
aws iam get-role --role-name $(terraform output -raw sagemaker_iam_role_name)

# Verify VPC endpoints are accessible
kubectl run test-pod --image=busybox --rm -it --restart=Never -- nslookup ec2.us-east-2.amazonaws.com
```

## Validation Checklist

### Phase 1 - Network Stack
- [ ] VPC created with correct CIDR block
- [ ] Public subnets created in multiple AZs
- [ ] Private subnet created for HyperPod
- [ ] EKS private subnets created in multiple AZs
- [ ] EKS private node subnet created
- [ ] Route tables configured correctly (including EKS node route table)
- [ ] NAT Gateway created (if not closed network)
- [ ] Internet Gateway created (if not closed network)
- [ ] Network outputs captured successfully (including EKS subnet IDs)

### Phase 2 - Cluster Stack
- [ ] EKS cluster created successfully
- [ ] EKS cluster uses existing VPC and EKS subnets
- [ ] EKS cluster references existing EKS private subnets and node subnet
- [ ] Security groups created with appropriate rules
- [ ] S3 bucket created for lifecycle scripts
- [ ] IAM roles created with correct permissions
- [ ] VPC endpoints created for AWS services
- [ ] Helm chart deployed successfully
- [ ] HyperPod cluster created and healthy
- [ ] Container images available in ECR (closed network)

### Integration Testing
- [ ] EKS nodes can communicate with HyperPod instances
- [ ] All pods running in kube-system namespace
- [ ] VPC endpoints accessible from both EKS and HyperPod
- [ ] S3 bucket accessible from both environments
- [ ] No internet access in closed network mode
- [ ] Security groups allow required traffic only

## Troubleshooting Common Issues

### Network Stack Issues

**Issue**: VPC CIDR conflicts
```bash
# Check existing VPCs in region
aws ec2 describe-vpcs --region us-east-2

# Modify CIDR blocks in network.tfvars if conflicts exist
```

**Issue**: Availability Zone not available
```bash
# List available AZs
aws ec2 describe-availability-zones --region us-east-2

# Update availability_zone_id and eks_availability_zones in configuration
```

### Cluster Stack Issues

**Issue**: EKS cluster creation fails
```bash
# Check EKS service limits
aws service-quotas get-service-quota --service-code eks --quota-code L-1194D53C --region us-east-2

# Verify subnet has sufficient IP addresses
aws ec2 describe-subnets --subnet-ids <subnet-id> --region us-east-2
```

**Issue**: HyperPod instance launch fails
```bash
# Check SageMaker service limits
aws service-quotas list-service-quotas --service-code sagemaker --region us-east-2

# Verify instance type availability
aws ec2 describe-instance-type-offerings --location-type availability-zone --filters Name=instance-type,Values=ml.g5.2xlarge --region us-east-2
```

**Issue**: VPC endpoint connectivity problems
```bash
# Check VPC endpoint status
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$VPC_ID" --region us-east-2

# Verify security group rules allow HTTPS traffic
aws ec2 describe-security-groups --group-ids $SECURITY_GROUP_ID --region us-east-2
```

### Container Image Issues (Closed Network)

**Issue**: ECR authentication fails
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-2.amazonaws.com
```

**Issue**: Image pull failures
```bash
# Verify images exist in ECR
aws ecr list-images --repository-name aws-efa-k8s-device-plugin --region us-east-2

# Check ECR repository policies
aws ecr get-repository-policy --repository-name aws-efa-k8s-device-plugin --region us-east-2
```

## Cleanup Process

### Cleanup Order (Important!)

1. **Destroy Cluster Stack First**:
```bash
cd awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf
terraform destroy -var-file="cluster.tfvars"
```

2. **Then Destroy Network Stack**:
```bash
terraform destroy -var-file="network.tfvars"
```

3. **Clean up ECR repositories** (if needed):
```bash
cd ../../../../..
# List ECR repositories
make list-ecr-repos REGION=us-east-2

# Delete ECR repositories manually if needed
aws ecr delete-repository --repository-name aws-efa-k8s-device-plugin --force --region us-east-2
```

## Advanced Testing Scenarios

### Multi-Region Testing

Test the same scenario in different regions:

```bash
# Update region in both configuration files
sed -i 's/us-east-2/us-west-2/g' network.tfvars cluster.tfvars
sed -i 's/use2-az1/usw2-az1/g' network.tfvars cluster.tfvars
sed -i 's/use2-az2/usw2-az2/g' network.tfvars cluster.tfvars

# Repeat deployment process
```

### Different Instance Types

Test with various HyperPod instance types:

```hcl
instance_groups = {
  cpu-group = {
    instance_type = "ml.m5.large"
    instance_count = 1
    # ... other settings
  }
  gpu-group = {
    instance_type = "ml.p3.2xlarge"
    instance_count = 1
    # ... other settings
  }
}
```

### Network Connectivity Variations

Test different network configurations:

1. **Fully closed network** (no internet access)
2. **Partially closed** (outbound through NAT)
3. **Open network** (with internet gateway)

## Performance Testing

### Resource Creation Time

Monitor deployment times:

```bash
# Time network stack deployment
time terraform apply network.tfplan

# Time cluster stack deployment
time terraform apply cluster.tfplan
```

### Resource Utilization

Monitor AWS service usage during deployment:

```bash
# Check CloudTrail for API calls
aws logs filter-log-events --log-group-name CloudTrail/APIGateway --start-time $(date -d '1 hour ago' +%s)000

# Monitor CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/EKS --metric-name cluster.numberOfNodes --start-time $(date -d '1 hour ago' --iso-8601) --end-time $(date --iso-8601) --period 300 --statistics Average
```

This comprehensive testing guide ensures thorough validation of the existing VPC deployment scenario, covering both infrastructure phases and various testing scenarios to verify proper functionality and integration.