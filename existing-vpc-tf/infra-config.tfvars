# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-08de163d8a0212b3c"
existing_private_subnet_id = "subnet-04d04b94583bc0760"
existing_private_route_table_id = "rtb-00bac528317c32b74"
existing_eks_private_subnet_ids = ["subnet-0ff48e28b2f7ce668","subnet-082cadd8936444540"]
existing_eks_private_node_subnet_id = "subnet-0a8fa3ad66b3d6a44"
existing_eks_private_node_route_table_id = "rtb-0de95331d1de2090e"


# Availability zone configuration
availability_zone_id = "use2-az2"
