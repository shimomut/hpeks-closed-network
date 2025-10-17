# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-0bcc4dc3b2571ce52"
existing_private_subnet_id = "subnet-0e816fe15bf4adeac"
existing_private_route_table_id = "rtb-0b8e139c7938a561d"
existing_eks_private_subnet_ids = ["subnet-0c0f3a9d1db088213","subnet-087456587028a2c00"]
existing_eks_private_node_subnet_id = "subnet-016e226cc358a0435"
existing_eks_private_node_route_table_id = "rtb-0ca999468998f2b9d"


# Availability zone configuration
availability_zone_name = "us-east-2b"
availability_zone_id = "use2-az2"
