# Infrastructure created by existing-vpc-tf
# Copy these values to your main HyperPod deployment terraform.tfvars

# Module control - use existing infrastructure
create_vpc_module = false
create_private_subnet_module = false
create_eks_subnets_module = false
create_security_group_module = true

# Existing infrastructure IDs
existing_vpc_id = "vpc-0b27524a7c2333566"
existing_private_subnet_id = "subnet-0c4afd01329935127"
existing_private_route_table_id = "rtb-0dd8528e03725e717"
existing_eks_private_subnet_ids = ["subnet-02be75084e30554ec","subnet-0e7833067c6acd99c"]
existing_eks_private_node_subnet_id = "subnet-0057ef641bf6c5606"
existing_eks_private_node_route_table_id = "rtb-0a831d3ec242b7e24"


# Availability zone configuration
availability_zone_name = "us-east-2b"
availability_zone_id = "use2-az2"
