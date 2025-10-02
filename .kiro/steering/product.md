# Product Overview

## HyperPod EKS Closed Network

This project customizes Terraform modules and Helm charts to deploy Amazon SageMaker HyperPod on Amazon EKS in a closed network environment. It leverages existing open-source components from AWS and modifies them specifically for secure, isolated deployments.

## Key Components
- **Terraform customizations**: Modified files from `awsome-distributed-training/1.architectures/7.sagemaker-hyperpod-eks/terraform-modules/hyperpod-eks-tf`
- **Helm chart customizations**: Modified files from `sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart`
- **Closed network architecture**: Specialized configurations for air-gapped environments

## Project Scope
- Focuses only on specific Terraform and Helm chart modifications
- Does not modify other files in the submodules
- Provides a unified deployment approach through customized configurations

## Target Use Cases
- Enterprise ML workloads requiring network isolation
- Regulated industries with strict security requirements
- Air-gapped environments needing HyperPod capabilities