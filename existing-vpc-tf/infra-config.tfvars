# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-0a5144e71b76f9aec"
existing_private_subnet_id = "subnet-0855433581c75ef16"
existing_private_route_table_id = "rtb-0053c81fc3b6c4299"
existing_eks_private_subnet_ids = ["subnet-0f29a0475a329daf0","subnet-054ffdd3c0c24adca"]
existing_eks_private_node_subnet_id = "subnet-09addc017c6fbcc99"
existing_eks_private_node_route_table_id = "rtb-0566d385edfa65570"


# Availability zone configuration
availability_zone_id = "use2-az2"
