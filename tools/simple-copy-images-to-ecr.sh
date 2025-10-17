#!/bin/bash

# Simple script to copy container images to ECR
# Usage: ./simple-copy-images-to-ecr.sh AWS_REGION AWS_ACCOUNT_ID

# Set variables
REGION=$1
ACCOUNT_ID=$2

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Login to source registries
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 602401143452.dkr.ecr.us-west-2.amazonaws.com
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 905418368575.dkr.ecr.us-west-2.amazonaws.com

# AWS EFA Device Plugin
echo "Processing aws-efa-k8s-device-plugin..."
SOURCE_IMAGE="602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin:v0.5.6"
TARGET_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/aws-efa-k8s-device-plugin"

aws ecr create-repository --repository-name aws-efa-k8s-device-plugin --region $REGION
docker pull --platform linux/amd64 $SOURCE_IMAGE
docker tag $SOURCE_IMAGE $TARGET_REPO:latest
docker tag $SOURCE_IMAGE $TARGET_REPO:v0.5.6
docker push $TARGET_REPO:latest
docker push $TARGET_REPO:v0.5.6

# HyperPod Health Monitoring Agent
echo "Processing hyperpod-health-monitoring-agent..."
SOURCE_IMAGE="905418368575.dkr.ecr.us-west-2.amazonaws.com/hyperpod-health-monitoring-agent:1.0.819.0_1.0.267.0"
TARGET_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/hyperpod-health-monitoring-agent"

aws ecr create-repository --repository-name hyperpod-health-monitoring-agent --region $REGION
docker pull --platform linux/amd64 $SOURCE_IMAGE
docker tag $SOURCE_IMAGE $TARGET_REPO:latest
docker tag $SOURCE_IMAGE $TARGET_REPO:1.0.819.0_1.0.267.0
docker push $TARGET_REPO:latest
docker push $TARGET_REPO:1.0.819.0_1.0.267.0

# NVIDIA Device Plugin
echo "Processing nvidia-k8s-device-plugin..."
SOURCE_IMAGE="nvcr.io/nvidia/k8s-device-plugin:v0.16.1"
TARGET_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/nvidia-k8s-device-plugin"

aws ecr create-repository --repository-name nvidia-k8s-device-plugin --region $REGION
docker pull --platform linux/amd64 $SOURCE_IMAGE
docker tag $SOURCE_IMAGE $TARGET_REPO:latest
docker tag $SOURCE_IMAGE $TARGET_REPO:v0.16.1
docker push $TARGET_REPO:latest
docker push $TARGET_REPO:v0.16.1

# MPI Operator
echo "Processing mpi-operator..."
SOURCE_IMAGE="mpioperator/mpi-operator:0.5"
TARGET_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/mpi-operator"

aws ecr create-repository --repository-name mpi-operator --region $REGION
docker pull --platform linux/amd64 $SOURCE_IMAGE
docker tag $SOURCE_IMAGE $TARGET_REPO:latest
docker tag $SOURCE_IMAGE $TARGET_REPO:0.5
docker push $TARGET_REPO:latest
docker push $TARGET_REPO:0.5

# Kubeflow Training Operator
echo "Processing kubeflow-training-operator..."
SOURCE_IMAGE="kubeflow/training-operator:v1-855e096"
TARGET_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/kubeflow-training-operator"

aws ecr create-repository --repository-name kubeflow-training-operator --region $REGION
docker pull --platform linux/amd64 $SOURCE_IMAGE
docker tag $SOURCE_IMAGE $TARGET_REPO:latest
docker tag $SOURCE_IMAGE $TARGET_REPO:v1-855e096
docker push $TARGET_REPO:latest
docker push $TARGET_REPO:v1-855e096

echo "All images copied to ECR successfully!"