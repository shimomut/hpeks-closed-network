# Image Repository and Tag Identification

## Methodology for Accurate Image Information

When identifying container image repositories and tags for ECR copying or configuration, always extract the actual values from the Helm charts rather than making assumptions.

## Step-by-Step Process

### 1. Check Chart Dependencies
First, examine the main `Chart.yaml` to understand chart dependencies and their versions:
```bash
# Check the main HyperPod chart dependencies
cat sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/Chart.yaml
```

### 2. Download External Charts
For external chart dependencies (from remote repositories), download the specific version:
```bash
# Add the repository if not already added
helm repo add eks https://aws.github.io/eks-charts/
helm repo update

# Download the specific chart version mentioned in Chart.yaml
helm pull eks/aws-efa-k8s-device-plugin --version 0.5.10 --untar

# Extract image information from the downloaded chart
cat aws-efa-k8s-device-plugin/values.yaml
```

### 3. Check Local Charts
For local chart dependencies (file:// repositories), examine the charts directly:
```bash
# Check local chart values
cat sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/charts/mpi-operator/values.yaml
cat sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/charts/health-monitoring-agent/values.yaml
```

### 4. Extract Image Information
Look for the `image` section in `values.yaml` files:
```yaml
image:
  repository: 602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin
  tag: "v0.5.6"
```

## Key Principles

1. **Never assume image tags** - Always verify from actual chart values
2. **Use exact chart versions** - Match the versions specified in Chart.yaml dependencies
3. **Check both repository and tag** - Both values may differ from expectations
4. **Document the source** - Include comments showing which chart and version the values came from
5. **Handle dynamic images** - Some charts (like health-monitoring-agent) construct image URIs dynamically

## Common Patterns

### External Charts
- AWS EKS charts: Usually from `602401143452.dkr.ecr.us-west-2.amazonaws.com`
- NVIDIA charts: Usually from `nvcr.io/nvidia`
- Community charts: Various registries (Docker Hub, Quay, etc.)

### Local Charts
- May reference external images or use custom build processes
- Check for dynamic URI construction based on region or other parameters
- Look for default values and override mechanisms

## Verification Commands

```bash
# List available chart versions
helm search repo eks/aws-efa-k8s-device-plugin --versions

# Show chart values without installing
helm show values eks/aws-efa-k8s-device-plugin --version 0.5.10

# Template the chart to see final rendered values
helm template test-release eks/aws-efa-k8s-device-plugin --version 0.5.10
```

## Update Process

When updating `tools/ecr-images.conf`:
1. Follow the methodology above to get accurate values
2. Include comments showing the source chart and version
3. Note any special considerations (dynamic URIs, region dependencies, etc.)
4. Test the configuration with the ECR copy scripts

This ensures that the ECR image copying process uses the correct, verified image references that match the actual Helm chart deployments.