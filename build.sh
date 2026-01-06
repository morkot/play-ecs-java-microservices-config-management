#!/bin/bash
set -e

# Build all services and push Docker images to ECR

# Detect container runtime (docker or podman)
if command -v docker &>/dev/null; then
    CONTAINER_CMD="docker"
elif command -v podman &>/dev/null; then
    CONTAINER_CMD="podman"
else
    echo "ERROR: Neither docker nor podman found."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo "ERROR: AWS credentials not configured."
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo "WARNING: AWS_REGION not set, using default: eu-west-1"
    AWS_REGION="eu-west-1"
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

echo "=== Building for AWS Account: $AWS_ACCOUNT, Region: $AWS_REGION (using $CONTAINER_CMD) ==="

# Login to ECR
echo "=== Logging in to ECR ==="
aws ecr get-login-password --region $AWS_REGION | $CONTAINER_CMD login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com

# Build framework
echo "=== Building framework ==="
cd app/framework
mvn clean install -q
cd ../..

# Build and push service-1
echo "=== Building service-1 ==="
cd app/service-1
mvn clean package -DskipTests -q
$CONTAINER_CMD build -t $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-1 .
echo "=== Pushing service-1 to ECR ==="
$CONTAINER_CMD push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-1
cd ../..

# Build and push service-2
echo "=== Building service-2 ==="
cd app/service-2
mvn clean package -DskipTests -q
$CONTAINER_CMD build -t $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-2 .
echo "=== Pushing service-2 to ECR ==="
$CONTAINER_CMD push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-2
cd ../..

echo "=== Build complete ==="
