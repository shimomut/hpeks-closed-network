#!/bin/bash

# Update Helm values.yaml files with ECR image references
# This script updates image repositories and tags in values.yaml files based on ECR configuration

set -e

# Check for help flag first
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help() {
        echo "Usage: $0 [REGION] [ACCOUNT_ID]"
        echo
        echo "Update Helm values.yaml files with ECR image references"
        echo
        echo "Arguments:"
        echo "  REGION      AWS region for ECR repositories (default: us-west-2)"
        echo "  ACCOUNT_ID  AWS account ID for ECR repositories (default: auto-detect)"
        echo
        echo "Examples:"
        echo "  $0                           # Use defaults (us-west-2, auto-detect account)"
        echo "  $0 us-east-1                 # Use us-east-1, auto-detect account"
        echo "  $0 us-east-1 123456789012    # Use us-east-1 and specific account ID"
        echo
        echo "Configuration:"
        echo "  ECR images are defined in: tools/ecr-images.conf"
        echo "  Values file updated:"
        echo "    • sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/values.yaml"
    }
    show_help
    exit 0
fi

# Configuration
ECR_CONFIG_FILE="tools/ecr-images.conf"
MAIN_VALUES_FILE="sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/values.yaml"

# Default values
REGION=${1:-"us-west-2"}
ACCOUNT_ID=${2:-"auto"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Updating Helm values.yaml files with ECR image references...${NC}"
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo

# Function to get account ID if set to auto
get_account_id() {
    if [ "$ACCOUNT_ID" = "auto" ]; then
        echo -e "${YELLOW}Auto-detecting AWS account ID...${NC}"
        DETECTED_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")
        if [ -n "$DETECTED_ACCOUNT_ID" ]; then
            echo "Detected account ID: $DETECTED_ACCOUNT_ID"
            ACCOUNT_ID="$DETECTED_ACCOUNT_ID"
        else
            echo -e "${RED}Error: Could not auto-detect account ID. Please provide it as second argument.${NC}"
            exit 1
        fi
    fi
}

# Function to parse ECR config and extract image info
parse_ecr_config() {
    if [ ! -f "$ECR_CONFIG_FILE" ]; then
        echo -e "${RED}Error: ECR config file not found: $ECR_CONFIG_FILE${NC}"
        exit 1
    fi
    
    # Parse the config file and extract image mappings
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        
        # Extract repository and tag from the value
        if [[ $value =~ ^(.+):(.+)$ ]]; then
            repo="${BASH_REMATCH[1]}"
            tag="${BASH_REMATCH[2]}"
            
            case $key in
                "aws-efa-k8s-device-plugin")
                    EFA_REPO="$repo"
                    EFA_TAG="$tag"
                    ;;
                "hyperpod-health-monitoring-agent")
                    HMA_REPO="$repo"
                    HMA_TAG="$tag"
                    ;;
                "nvidia-k8s-device-plugin")
                    NVIDIA_REPO="$repo"
                    NVIDIA_TAG="$tag"
                    ;;
                "mpi-operator")
                    MPI_REPO="$repo"
                    MPI_TAG="$tag"
                    ;;
            esac
        fi
    done < "$ECR_CONFIG_FILE"
}

# Function to update ECR repository URLs with target account and region
update_ecr_urls() {
    get_account_id
    
    # Update ECR URLs to use target account and region
    if [[ $EFA_REPO =~ \.dkr\.ecr\. ]]; then
        EFA_REPO=$(echo "$EFA_REPO" | sed "s/[0-9]\{12\}\.dkr\.ecr\.[^.]*\.amazonaws\.com/$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/")
    fi
    
    if [[ $HMA_REPO =~ \.dkr\.ecr\. ]]; then
        HMA_REPO=$(echo "$HMA_REPO" | sed "s/[0-9]\{12\}\.dkr\.ecr\.[^.]*\.amazonaws\.com/$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/")
    fi
    
    if [[ $NVIDIA_REPO =~ \.dkr\.ecr\. ]]; then
        NVIDIA_REPO=$(echo "$NVIDIA_REPO" | sed "s/[0-9]\{12\}\.dkr\.ecr\.[^.]*\.amazonaws\.com/$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/")
    fi
    
    if [[ $MPI_REPO =~ \.dkr\.ecr\. ]]; then
        MPI_REPO=$(echo "$MPI_REPO" | sed "s/[0-9]\{12\}\.dkr\.ecr\.[^.]*\.amazonaws\.com/$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/")
    fi
}

# Function to backup a file
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
        echo -e "${GREEN}✓${NC} Backed up $file"
    fi
}

# Function to update main values.yaml file with ECR image overrides
update_main_values() {
    if [ ! -f "$MAIN_VALUES_FILE" ]; then
        echo -e "${RED}Error: Main values file not found: $MAIN_VALUES_FILE${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Updating main values.yaml file with ECR image overrides...${NC}"
    backup_file "$MAIN_VALUES_FILE"
    
    # Create a temporary file for the updated values
    local temp_file="$MAIN_VALUES_FILE.tmp"
    cp "$MAIN_VALUES_FILE" "$temp_file"
    
    # Add ECR image overrides at the end of the file
    echo "" >> "$temp_file"
    echo "# ECR Image Overrides for Air-Gapped Environment" >> "$temp_file"
    echo "# Generated by update-values-with-ecr.sh" >> "$temp_file"
    echo "" >> "$temp_file"
    
    # Add NVIDIA device plugin image override
    if [ -n "$NVIDIA_REPO" ]; then
        echo "# Override NVIDIA device plugin image" >> "$temp_file"
        echo "nvidia-device-plugin:" >> "$temp_file"
        echo "  image:" >> "$temp_file"
        echo "    repository: $NVIDIA_REPO" >> "$temp_file"
        echo "" >> "$temp_file"
        echo -e "${GREEN}✓${NC} Added NVIDIA device plugin override: $NVIDIA_REPO:$NVIDIA_TAG"
    fi
    
    # Add AWS EFA device plugin image override
    if [ -n "$EFA_REPO" ]; then
        echo "# Override AWS EFA device plugin image" >> "$temp_file"
        echo "aws-efa-k8s-device-plugin:" >> "$temp_file"
        echo "  image:" >> "$temp_file"
        echo "    repository: $EFA_REPO" >> "$temp_file"
        echo "" >> "$temp_file"
        echo -e "${GREEN}✓${NC} Added AWS EFA device plugin override: $EFA_REPO:$EFA_TAG"
    fi
    
    # Add MPI operator image override
    if [ -n "$MPI_REPO" ]; then
        echo "# Override MPI operator image" >> "$temp_file"
        echo "mpi-operator:" >> "$temp_file"
        echo "  mpiOperator:" >> "$temp_file"
        echo "    image:" >> "$temp_file"
        echo "      repository: $MPI_REPO" >> "$temp_file"
        echo "" >> "$temp_file"
        echo -e "${GREEN}✓${NC} Added MPI operator override: $MPI_REPO:$MPI_TAG"
    fi
    
    # Add health monitoring agent image override
    if [ -n "$HMA_REPO" ] && [ -n "$HMA_TAG" ]; then
        local full_image="$HMA_REPO:$HMA_TAG"
        echo "# Override health monitoring agent image" >> "$temp_file"
        echo "health-monitoring-agent:" >> "$temp_file"
        echo "  hmaimage: \"$full_image\"" >> "$temp_file"
        echo "" >> "$temp_file"
        echo -e "${GREEN}✓${NC} Added health monitoring agent override: $full_image"
    fi
    
    # Replace the original file with the updated version
    mv "$temp_file" "$MAIN_VALUES_FILE"
    
    echo -e "${GREEN}✓${NC} Updated main values.yaml file with ECR image overrides"
}

# Function to show summary
show_summary() {
    echo
    echo -e "${BLUE}=== Update Summary ===${NC}"
    echo -e "${GREEN}✓${NC} Updated Helm values.yaml files with ECR image references"
    echo
    echo "Updated images:"
    [ -n "$NVIDIA_REPO" ] && echo "  • NVIDIA Device Plugin: $NVIDIA_REPO:$NVIDIA_TAG"
    [ -n "$EFA_REPO" ] && echo "  • AWS EFA Device Plugin: $EFA_REPO:$EFA_TAG"
    [ -n "$MPI_REPO" ] && echo "  • MPI Operator: $MPI_REPO:$MPI_TAG"
    [ -n "$HMA_REPO" ] && echo "  • Health Monitoring Agent: $HMA_REPO:$HMA_TAG"
    echo
    echo "Target ECR configuration:"
    echo "  • Region: $REGION"
    echo "  • Account ID: $ACCOUNT_ID"
    echo
    echo -e "${YELLOW}Note:${NC} Image overrides have been added to the top-level values.yaml file."
    echo "      These overrides will be used by all subcharts during deployment."
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Review the updated values.yaml files"
    echo "  2. Run 'helm dependency update' to update external chart dependencies"
    echo "  3. Deploy with 'helm install' or 'helm upgrade'"
}

# Main execution
main() {
    echo -e "${BLUE}Parsing ECR configuration...${NC}"
    parse_ecr_config
    
    echo -e "${BLUE}Updating ECR URLs for target account and region...${NC}"
    update_ecr_urls
    
    update_main_values
    
    show_summary
}



# Run main function
main