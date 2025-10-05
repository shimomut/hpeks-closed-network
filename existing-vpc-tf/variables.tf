# Variables for Infrastructure Creation Stack
# This creates VPC, Subnets, Route Tables, and Security Groups

variable "resource_name_prefix" {
  description = "Prefix to be used for all resources"
  type        = string
  default     = "hpeks-infra"
}

variable "aws_region" {
  description = "AWS Region to be targeted for deployment"
  type        = string
  default     = "us-west-2"
}

# Network Configuration
variable "closed_network" {
  description = "Whether to deploy in closed network mode (no internet gateway, NAT gateways, or EIPs)"
  type        = bool
  default     = true
}

variable "vpc_cidr" {
  description = "The IP range (CIDR notation) for the VPC"
  type        = string
  default     = "10.192.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "List of IP ranges (CIDR notation) for public subnets (used for NAT gateways if not closed network)"
  type        = list(string)
  default     = ["10.192.10.0/24", "10.192.11.0/24"]
}

# HyperPod Subnet Configuration
variable "hyperpod_private_subnet_cidr" {
  description = "The IP range (CIDR notation) for the HyperPod private subnet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "hyperpod_availability_zone_index" {
  description = "Index of the availability zone for HyperPod private subnet (0-based)"
  type        = number
  default     = 1
  validation {
    condition     = var.hyperpod_availability_zone_index >= 0 && var.hyperpod_availability_zone_index <= 2
    error_message = "Availability zone index must be between 0 and 2."
  }
}

# EKS Subnets Configuration
variable "eks_private_subnet_cidrs" {
  description = "List of IP ranges (CIDR notation) for EKS private subnets (control plane)"
  type        = list(string)
  default     = ["10.192.7.0/24", "10.192.8.0/24"]
  validation {
    condition     = length(var.eks_private_subnet_cidrs) >= 2
    error_message = "At least 2 CIDR blocks must be specified for EKS private subnets."
  }
}

variable "eks_private_node_subnet_cidr" {
  description = "The IP range (CIDR notation) for the EKS private node subnet"
  type        = string
  default     = "10.192.9.0/24"
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster (used for subnet tagging)"
  type        = string
  default     = "hpeks-test-cluster"
}