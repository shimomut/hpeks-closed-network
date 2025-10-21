# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-06dd0d4c2d2e96eac"
existing_private_subnet_id = "subnet-0b790d22806a2dc1e"
existing_private_route_table_id = "rtb-0355709ce180fedb2"
existing_eks_private_subnet_ids = ["subnet-0df08280258840e15","subnet-0b415db5b904a906c"]
existing_eks_private_node_subnet_id = "subnet-0420797cb9805e6e3"
existing_eks_private_node_route_table_id = "rtb-053a575153618b242"


# Availability zone configuration
availability_zone_id = "use2-az2"
