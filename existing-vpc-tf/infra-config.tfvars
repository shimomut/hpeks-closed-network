# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-09effde6a8e2bca82"
existing_private_subnet_id = "subnet-0d0421c62f50d5daa"
existing_private_route_table_id = "rtb-0e06985cb16f63736"
existing_eks_private_subnet_ids = ["subnet-04458eb2b61c70822","subnet-0b4e58f90afb2634b"]
existing_eks_private_node_subnet_id = "subnet-0368c2982e6879e45"
existing_eks_private_node_route_table_id = "rtb-06b53ab51fe9fac7d"


# Availability zone configuration
availability_zone_id = "us-east-2b"
