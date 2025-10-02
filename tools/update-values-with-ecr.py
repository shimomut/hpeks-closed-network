#!/usr/bin/env python3

"""
Update Helm values.yaml files with ECR image references
This script updates image repositories and tags in values.yaml files based on ECR configuration
"""

import argparse
import os
import sys
import re
import subprocess
from datetime import datetime
from pathlib import Path

try:
    from ruamel.yaml import YAML
except ImportError:
    print("Error: ruamel.yaml is required. Install with: pip install ruamel.yaml")
    sys.exit(1)

# Colors for output
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color

def print_colored(message, color):
    """Print message with color"""
    print(f"{color}{message}{Colors.NC}")

def get_account_id():
    """Auto-detect AWS account ID"""
    try:
        result = subprocess.run(
            ['aws', 'sts', 'get-caller-identity', '--query', 'Account', '--output', 'text'],
            capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None

def parse_ecr_config(config_file):
    """Parse ECR configuration file and extract image mappings"""
    if not os.path.exists(config_file):
        print_colored(f"Error: ECR config file not found: {config_file}", Colors.RED)
        sys.exit(1)
    
    images = {}
    with open(config_file, 'r') as f:
        for line in f:
            line = line.strip()
            # Skip comments and empty lines
            if line.startswith('#') or not line:
                continue
            
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Extract repository and tag
                if ':' in value:
                    repo, tag = value.rsplit(':', 1)
                    images[key] = {'repo': repo, 'tag': tag, 'full': value}
    
    return images

def update_ecr_urls(images, region, account_id):
    """Update ECR repository URLs with target account and region"""
    ecr_pattern = re.compile(r'\d{12}\.dkr\.ecr\.[^.]+\.amazonaws\.com')
    
    for key, image_info in images.items():
        repo = image_info['repo']
        tag = image_info['tag']
        
        # Only update ECR URLs
        if ecr_pattern.search(repo):
            new_repo = ecr_pattern.sub(f"{account_id}.dkr.ecr.{region}.amazonaws.com", repo)
            images[key]['repo'] = new_repo
            images[key]['full'] = f"{new_repo}:{tag}"
    
    return images

def backup_file(file_path):
    """Create backup of file"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup.{timestamp}"
    
    if os.path.exists(file_path):
        import shutil
        shutil.copy2(file_path, backup_path)
        print_colored(f"✓ Backed up {file_path}", Colors.GREEN)
        return backup_path
    return None

def update_values_yaml(values_file, images):
    """Update the values.yaml file with ECR image overrides"""
    if not os.path.exists(values_file):
        print_colored(f"Error: Values file not found: {values_file}", Colors.RED)
        return False
    
    # Initialize YAML parser with comment preservation
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.width = 4096  # Prevent line wrapping
    
    # Load the YAML file
    with open(values_file, 'r') as f:
        data = yaml.load(f)
    
    if data is None:
        data = {}
    
    updated_images = []
    
    # Update NVIDIA device plugin
    if 'nvidia-k8s-device-plugin' in images:
        image_info = images['nvidia-k8s-device-plugin']
        if 'nvidia-device-plugin' not in data:
            data['nvidia-device-plugin'] = {}
        
        # Add comment and image config
        data['nvidia-device-plugin']['image'] = {
            'repository': image_info['repo']
        }
        
        # Add comment before the image section
        if hasattr(data['nvidia-device-plugin'], 'yaml_set_comment_before_after_key'):
            data['nvidia-device-plugin'].yaml_set_comment_before_after_key(
                'image', before='ECR override for air-gapped environment'
            )
        
        updated_images.append(f"NVIDIA Device Plugin: {image_info['full']}")
        print_colored(f"✓ Added NVIDIA device plugin override: {image_info['full']}", Colors.GREEN)
    
    # Update AWS EFA device plugin
    if 'aws-efa-k8s-device-plugin' in images:
        image_info = images['aws-efa-k8s-device-plugin']
        if 'aws-efa-k8s-device-plugin' not in data:
            data['aws-efa-k8s-device-plugin'] = {}
        
        data['aws-efa-k8s-device-plugin']['image'] = {
            'repository': image_info['repo']
        }
        
        if hasattr(data['aws-efa-k8s-device-plugin'], 'yaml_set_comment_before_after_key'):
            data['aws-efa-k8s-device-plugin'].yaml_set_comment_before_after_key(
                'image', before='ECR override for air-gapped environment'
            )
        
        updated_images.append(f"AWS EFA Device Plugin: {image_info['full']}")
        print_colored(f"✓ Added AWS EFA device plugin override: {image_info['full']}", Colors.GREEN)
    
    # Update MPI operator
    if 'mpi-operator' in images:
        image_info = images['mpi-operator']
        if 'mpi-operator' not in data:
            data['mpi-operator'] = {}
        
        data['mpi-operator']['mpiOperator'] = {
            'image': {
                'repository': image_info['repo']
            }
        }
        
        if hasattr(data['mpi-operator'], 'yaml_set_comment_before_after_key'):
            data['mpi-operator'].yaml_set_comment_before_after_key(
                'mpiOperator', before='ECR override for air-gapped environment'
            )
        
        updated_images.append(f"MPI Operator: {image_info['full']}")
        print_colored(f"✓ Added MPI operator override: {image_info['full']}", Colors.GREEN)
    
    # Update health monitoring agent
    if 'hyperpod-health-monitoring-agent' in images:
        image_info = images['hyperpod-health-monitoring-agent']
        if 'health-monitoring-agent' not in data:
            data['health-monitoring-agent'] = {}
        
        data['health-monitoring-agent']['hmaimage'] = image_info['full']
        
        if hasattr(data['health-monitoring-agent'], 'yaml_set_comment_before_after_key'):
            data['health-monitoring-agent'].yaml_set_comment_before_after_key(
                'hmaimage', before='ECR override for air-gapped environment'
            )
        
        updated_images.append(f"Health Monitoring Agent: {image_info['full']}")
        print_colored(f"✓ Added health monitoring agent override: {image_info['full']}", Colors.GREEN)
    
    # Write the updated YAML back to file
    with open(values_file, 'w') as f:
        yaml.dump(data, f)
    
    print_colored("✓ Updated main values.yaml file with ECR image overrides", Colors.GREEN)
    return updated_images

def show_summary(updated_images, region, account_id):
    """Show summary of updates"""
    print()
    print_colored("=== Update Summary ===", Colors.BLUE)
    print_colored("✓ Updated Helm values.yaml files with ECR image references", Colors.GREEN)
    print()
    
    if updated_images:
        print("Updated images:")
        for image in updated_images:
            print(f"  • {image}")
    else:
        print("No images were updated.")
    
    print()
    print("Target ECR configuration:")
    print(f"  • Region: {region}")
    print(f"  • Account ID: {account_id}")
    print()
    print_colored("Note: Image overrides have been added to the top-level values.yaml file.", Colors.YELLOW)
    print("      These overrides will be used by all subcharts during deployment.")
    print()
    print_colored("Next steps:", Colors.BLUE)
    print("  1. Review the updated values.yaml files")
    print("  2. Run 'helm dependency update' to update external chart dependencies")
    print("  3. Deploy with 'helm install' or 'helm upgrade'")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description="Update Helm values.yaml files with ECR image references",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                           # Use defaults (us-west-2, auto-detect account)
  %(prog)s us-east-1                 # Use us-east-1, auto-detect account
  %(prog)s us-east-1 123456789012    # Use us-east-1 and specific account ID

Configuration:
  ECR images are defined in: tools/ecr-images.conf
  Values file updated:
    • sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/values.yaml
        """
    )
    
    parser.add_argument(
        'region',
        nargs='?',
        default='us-west-2',
        help='AWS region for ECR repositories (default: us-west-2)'
    )
    
    parser.add_argument(
        'account_id',
        nargs='?',
        default='auto',
        help='AWS account ID for ECR repositories (default: auto-detect)'
    )
    
    args = parser.parse_args()
    
    # Configuration
    ecr_config_file = "tools/ecr-images.conf"
    main_values_file = "sagemaker-hyperpod-cli/helm_chart/HyperPodHelmChart/values.yaml"
    
    print_colored("Updating Helm values.yaml files with ECR image references...", Colors.BLUE)
    print(f"Region: {args.region}")
    print(f"Account ID: {args.account_id}")
    print()
    
    # Get account ID if set to auto
    if args.account_id == 'auto':
        print_colored("Auto-detecting AWS account ID...", Colors.YELLOW)
        detected_account_id = get_account_id()
        if detected_account_id:
            print(f"Detected account ID: {detected_account_id}")
            args.account_id = detected_account_id
        else:
            print_colored("Error: Could not auto-detect account ID. Please provide it as second argument.", Colors.RED)
            sys.exit(1)
    
    # Parse ECR configuration
    print_colored("Parsing ECR configuration...", Colors.BLUE)
    images = parse_ecr_config(ecr_config_file)
    
    # Update ECR URLs for target account and region
    print_colored("Updating ECR URLs for target account and region...", Colors.BLUE)
    images = update_ecr_urls(images, args.region, args.account_id)
    
    # Update main values.yaml file
    print_colored("Updating main values.yaml file with ECR image overrides...", Colors.BLUE)
    backup_file(main_values_file)
    updated_images = update_values_yaml(main_values_file, images)
    
    # Show summary
    show_summary(updated_images, args.region, args.account_id)

if __name__ == "__main__":
    main()