# Infrastructure Creation Configuration
# This creates the foundational VPC, Subnets, Route Tables, and Security Groups
# for testing HyperPod EKS deployment with existing infrastructure

resource_name_prefix = "hpeks-infra-test"
aws_region           = "us-east-2"

# Closed Network Configuration
# Set to true for air-gapped environments (no internet gateway, NAT gateways)
# Set to false if you need internet connectivity for initial setup
closed_network = true

# VPC Configuration
vpc_cidr = "10.192.0.0/16"

# Public subnets (only used if closed_network = false for NAT gateways)
public_subnet_cidrs = ["10.192.10.0/24", "10.192.11.0/24"]

# HyperPod Private Subnet Configuration
hyperpod_private_subnet_cidr = "10.1.0.0/16"
hyperpod_availability_zone_index = 1  # use2-az2 (second AZ)

# EKS Subnets Configuration
eks_private_subnet_cidrs = ["10.192.7.0/24", "10.192.8.0/24"]
eks_private_node_subnet_cidr = "10.192.9.0/24"

# EKS Cluster Name (for subnet tagging)
eks_cluster_name = "hpeks-test-cluster"