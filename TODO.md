- Remove public subnets / public route tables / route table associations

- Test by actually disabling internet access.

- Check if "endpoint_public_access" can be false

- There is no guarantee EKS subnets are created in the same AZ as the HyperPod subnet. Should explicitly list AZs?