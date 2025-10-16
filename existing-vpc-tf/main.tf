# Infrastructure Creation Stack for HyperPod EKS Closed Network Testing
# This stack creates VPC, Subnets, Route Tables, and Security Groups
# to be used by the main HyperPod deployment with existing infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get availability zones for the region
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the availability zone name from the AZ-ID for HyperPod
data "aws_availability_zone" "hyperpod_az" {
  zone_id = var.hyperpod_availability_zone_id
}

# Get the availability zone names from the AZ-IDs for EKS private subnets
data "aws_availability_zone" "eks_private_azs" {
  count   = length(var.eks_private_availability_zone_ids)
  zone_id = var.eks_private_availability_zone_ids[count.index]
}

# Get the availability zone name from the AZ-ID for EKS private node subnet
data "aws_availability_zone" "eks_private_node_az" {
  zone_id = var.eks_private_node_availability_zone_id
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.resource_name_prefix}-vpc"
  }
}

# Add additional CIDR block for HyperPod subnet
resource "aws_vpc_ipv4_cidr_block_association" "hyperpod_cidr" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.1.0.0/16"
}

# Create Internet Gateway (for closed network testing, this might be optional)
resource "aws_internet_gateway" "main" {
  count  = var.closed_network ? 0 : 1
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.resource_name_prefix}-igw"
  }
}

# Create public subnets (for NAT gateways if not closed network)
resource "aws_subnet" "public" {
  count                   = var.closed_network ? 0 : 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.resource_name_prefix}-public-subnet-${count.index + 1}"
  }
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.closed_network ? 0 : 1
  domain = "vpc"

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.resource_name_prefix}-nat-eip-${count.index + 1}"
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  count         = var.closed_network ? 0 : 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.resource_name_prefix}-nat-gateway"
  }
}

# Create HyperPod private subnet
resource "aws_subnet" "hyperpod_private" {
  depends_on = [aws_vpc_ipv4_cidr_block_association.hyperpod_cidr]
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.hyperpod_private_subnet_cidr
  availability_zone = data.aws_availability_zone.hyperpod_az.name

  tags = {
    Name = "${var.resource_name_prefix}-hyperpod-private-subnet"
  }
}

# Create EKS private subnets (for control plane)
resource "aws_subnet" "eks_private" {
  count             = length(var.eks_private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.eks_private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zone.eks_private_azs[count.index].name

  tags = {
    Name                              = "${var.resource_name_prefix}-eks-private-subnet-${count.index + 1}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

# Create EKS private node subnet
resource "aws_subnet" "eks_private_node" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.eks_private_node_subnet_cidr
  availability_zone = data.aws_availability_zone.eks_private_node_az.name

  tags = {
    Name                              = "${var.resource_name_prefix}-eks-private-node-subnet"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
  }
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  count  = var.closed_network ? 0 : 1
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name = "${var.resource_name_prefix}-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = var.closed_network ? 0 : 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

# Create route table for HyperPod private subnet
resource "aws_route_table" "hyperpod_private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.closed_network ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.resource_name_prefix}-hyperpod-private-rt"
  }
}

# Associate HyperPod private subnet with its route table
resource "aws_route_table_association" "hyperpod_private" {
  subnet_id      = aws_subnet.hyperpod_private.id
  route_table_id = aws_route_table.hyperpod_private.id
}

# Create route table for EKS private subnets
resource "aws_route_table" "eks_private" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.closed_network ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.resource_name_prefix}-eks-private-rt"
  }
}

# Associate EKS private subnets with EKS private route table
resource "aws_route_table_association" "eks_private" {
  count          = length(aws_subnet.eks_private)
  subnet_id      = aws_subnet.eks_private[count.index].id
  route_table_id = aws_route_table.eks_private.id
}

# Create route table for EKS private node subnet
resource "aws_route_table" "eks_private_node" {
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.closed_network ? [] : [1]
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = {
    Name = "${var.resource_name_prefix}-eks-private-node-rt"
  }
}

# Associate EKS private node subnet with its route table
resource "aws_route_table_association" "eks_private_node" {
  subnet_id      = aws_subnet.eks_private_node.id
  route_table_id = aws_route_table.eks_private_node.id
}

