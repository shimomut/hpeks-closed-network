#!/bin/bash

# Script to copy container images to ECR repositories
# Usage: ./copy-images-to-ecr.sh [AWS_REGION] [AWS_ACCOUNT_ID]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/ecr-images.conf"

# Configuration
DEFAULT_REGION="us-east-2"
REGION="${1:-$DEFAULT_REGION}"
ACCOUNT_ID="${2:-$(aws sts get-caller-identity --query Account --output text)}"

# Load images from configuration file
declare -A IMAGES
if [[ -f "$CONFIG_FILE" ]]; then
    while IFS='=' read -r repo_name source_image; do
        # Skip comments and empty lines
        [[ "$repo_name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$repo_name" ]] && continue
        
        # Remove leading/trailing whitespace
        repo_name=$(echo "$repo_name" | xargs)
        source_image=$(echo "$source_image" | xargs)
        
        IMAGES["$repo_name"]="$source_image"
    done < "$CONFIG_FILE"
else
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "🚀 Starting ECR image copy process..."
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo ""

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# Login to NVIDIA registry for nvcr.io images
echo "🔐 Logging into NVIDIA Container Registry..."
docker login nvcr.io

for repo_name in "${!IMAGES[@]}"; do
    source_image="${IMAGES[$repo_name]}"
    target_repo="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$repo_name"
    
    echo ""
    echo "📦 Processing $repo_name..."
    echo "  Source: $source_image"
    echo "  Target: $target_repo"
    
    # Check if ECR repository exists, create if not
    if ! aws ecr describe-repositories --repository-names "$repo_name" --region "$REGION" >/dev/null 2>&1; then
        echo "  📝 Creating ECR repository: $repo_name"
        aws ecr create-repository --repository-name "$repo_name" --region "$REGION" >/dev/null
        echo "  ✅ Repository created"
    else
        echo "  ✅ Repository exists"
    fi
    
    # Pull source image
    echo "  ⬇️  Pulling source image..."
    docker pull "$source_image"
    
    # Tag for ECR
    echo "  🏷️  Tagging image..."
    docker tag "$source_image" "$target_repo:latest"
    
    # Extract and tag with original version if available
    if [[ "$source_image" == *":"* ]]; then
        original_tag=$(echo "$source_image" | cut -d':' -f2)
        if [[ "$original_tag" != "latest" ]]; then
            docker tag "$source_image" "$target_repo:$original_tag"
            echo "  🏷️  Tagged with version: $original_tag"
        fi
    fi
    
    # Push to ECR
    echo "  ⬆️  Pushing to ECR..."
    docker push "$target_repo:latest"
    
    # Push version tag if it exists
    if [[ "$source_image" == *":"* ]]; then
        original_tag=$(echo "$source_image" | cut -d':' -f2)
        if [[ "$original_tag" != "latest" ]]; then
            docker push "$target_repo:$original_tag"
        fi
    fi
    
    echo "  ✅ Successfully copied $repo_name"
done

echo ""
echo "🎉 All images successfully copied to ECR!"
echo ""
echo "📋 Summary of created repositories:"
for repo_name in "${!IMAGES[@]}"; do
    echo "  • $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$repo_name"
done