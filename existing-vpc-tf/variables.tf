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

variable "hyperpod_availability_zone_id" {
  description = "Availability Zone ID for HyperPod private subnet (e.g., 'use2-az2')"
  type        = string
  default     = "use2-az2"
  validation {
    condition     = can(regex("^[a-z0-9]+-az[0-9]+$", var.hyperpod_availability_zone_id))
    error_message = "Availability zone ID must be in the format 'region-az#' (e.g., 'use2-az2')."
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

variable "eks_private_availability_zone_ids" {
  description = "List of Availability Zone IDs for EKS private subnets (e.g., ['use2-az1', 'use2-az3'])"
  type        = list(string)
  default     = ["use2-az1", "use2-az3"]
  validation {
    condition     = length(var.eks_private_availability_zone_ids) >= 2
    error_message = "At least 2 availability zone IDs must be specified for EKS private subnets."
  }
  validation {
    condition = alltrue([
      for az_id in var.eks_private_availability_zone_ids : can(regex("^[a-z0-9]+-az[0-9]+$", az_id))
    ])
    error_message = "All availability zone IDs must be in the format 'region-az#' (e.g., 'use2-az1')."
  }
  validation {
    condition     = length(var.eks_private_availability_zone_ids) == length(var.eks_private_subnet_cidrs)
    error_message = "The number of availability zone IDs must match the number of EKS private subnet CIDRs."
  }
}

variable "eks_private_node_subnet_cidr" {
  description = "The IP range (CIDR notation) for the EKS private node subnet"
  type        = string
  default     = "10.192.9.0/24"
}

variable "eks_private_node_availability_zone_id" {
  description = "Availability Zone ID for EKS private node subnet (e.g., 'use2-az1')"
  type        = string
  default     = "use2-az1"
  validation {
    condition     = can(regex("^[a-z0-9]+-az[0-9]+$", var.eks_private_node_availability_zone_id))
    error_message = "Availability zone ID must be in the format 'region-az#' (e.g., 'use2-az1')."
  }
}

variable "eks_cluster_name" {
  description = "The name of the EKS cluster (used for subnet tagging)"
  type        = string
  default     = "hpeks-test-cluster"
}