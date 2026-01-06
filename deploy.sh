#!/bin/bash
set -e

# Deploy all infrastructure in correct order

# Check required environment variables
if ! aws sts get-caller-identity &>/dev/null; then
    echo "ERROR: AWS credentials not configured."
    exit 1
fi

echo "=== Deploying platform (VPC, ALB, ECS Cluster) ==="
cd infra/platform
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deploying SSM parameters (dev) ==="
cd ../config/dev
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deploying SSM parameters (prod) ==="
cd ../prod
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deploying service-1 ==="
cd ../../service-1
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deploying service-2 ==="
cd ../service-2
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deploying Lambda config refresher ==="
cd ../lambda-config-refresh
terraform init -upgrade
terraform apply -auto-approve

echo "=== Deployment complete ==="
cd ../platform
ALB=$(terraform output -raw alb_endpoint)

echo ""
echo "=========================================="
echo "           API Endpoints"
echo "=========================================="
echo ""
echo "ALB: $ALB"
echo ""
echo "Service-1 (dev environment):"
echo "  GET  $ALB/service-1/api/config"
echo "  GET  $ALB/service-1/api/ssm-properties"
echo "  POST $ALB/service-1/api/config/refresh"
echo "  GET  $ALB/service-1/api/health"
echo ""
echo "Service-2 (prod environment):"
echo "  GET  $ALB/service-2/api/config"
echo "  GET  $ALB/service-2/api/ssm-properties"
echo "  POST $ALB/service-2/api/config/refresh"
echo "  GET  $ALB/service-2/api/health"
echo ""
echo "=========================================="
