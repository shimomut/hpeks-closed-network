#!/bin/bash

# Script to list ECR repositories that would be created
# Usage: ./list-ecr-repos.sh [AWS_REGION] [AWS_ACCOUNT_ID]

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/ecr-images.conf"

# Configuration
DEFAULT_REGION="us-east-2"
REGION="${1:-$DEFAULT_REGION}"
ACCOUNT_ID="${2:-$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "YOUR_ACCOUNT_ID")}"

echo "📋 ECR Repositories Configuration"
echo "Region: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo ""

if [[ -f "$CONFIG_FILE" ]]; then
    echo "🏗️  Repositories that will be created/used:"
    while IFS='=' read -r repo_name source_image; do
        # Skip comments and empty lines
        [[ "$repo_name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$repo_name" ]] && continue
        
        # Remove leading/trailing whitespace
        repo_name=$(echo "$repo_name" | xargs)
        source_image=$(echo "$source_image" | xargs)
        
        echo "  • $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$repo_name"
        echo "    Source: $source_image"
        echo ""
    done < "$CONFIG_FILE"
else
    echo "❌ Configuration file not found: $CONFIG_FILE"
    exit 1
fi

echo "💡 To copy these images to ECR, run:"
echo "   make copy-images-to-ecr"
echo "   # or with custom region/account:"
echo "   make copy-images-to-ecr REGION=us-west-2 ACCOUNT_ID=123456789012"