# Outputs for Infrastructure Stack
# These values will be used as inputs for the main HyperPod deployment

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.main.cidr_block
}

# HyperPod Infrastructure Outputs
output "hyperpod_private_subnet_id" {
  description = "ID of the HyperPod private subnet"
  value       = aws_subnet.hyperpod_private.id
}

output "hyperpod_private_route_table_id" {
  description = "ID of the HyperPod private route table"
  value       = aws_route_table.hyperpod_private.id
}

output "hyperpod_availability_zone" {
  description = "Availability zone of the HyperPod private subnet"
  value       = aws_subnet.hyperpod_private.availability_zone
}

# EKS Infrastructure Outputs
output "eks_private_subnet_ids" {
  description = "List of EKS private subnet IDs (for control plane)"
  value       = aws_subnet.eks_private[*].id
}

output "eks_private_node_subnet_id" {
  description = "ID of the EKS private node subnet"
  value       = aws_subnet.eks_private_node.id
}

output "eks_private_node_route_table_id" {
  description = "ID of the EKS private node route table"
  value       = aws_route_table.eks_private_node.id
}

output "eks_availability_zones" {
  description = "List of availability zones used for EKS subnets"
  value       = aws_subnet.eks_private[*].availability_zone
}



# NAT Gateway Output (if created)
output "nat_gateway_id" {
  description = "ID of the NAT Gateway (empty if closed network)"
  value       = var.closed_network ? "" : aws_nat_gateway.main[0].id
}

# Summary for easy copy-paste to main deployment
output "terraform_tfvars_snippet" {
  description = "Terraform tfvars snippet for main HyperPod deployment"
  value = <<-EOT
# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "${aws_vpc.main.id}"
existing_private_subnet_id = "${aws_subnet.hyperpod_private.id}"
existing_private_route_table_id = "${aws_route_table.hyperpod_private.id}"
existing_eks_private_subnet_ids = ${jsonencode(aws_subnet.eks_private[*].id)}
existing_eks_private_node_subnet_id = "${aws_subnet.eks_private_node.id}"
existing_eks_private_node_route_table_id = "${aws_route_table.eks_private_node.id}"
${var.closed_network ? "" : "existing_nat_gateway_id = \"${aws_nat_gateway.main[0].id}\""}

# Availability zone configuration
availability_zone_id = "${aws_subnet.hyperpod_private.availability_zone}"
EOT
}