#!/bin/bash
set -e

# Destroy all infrastructure in reverse order

# Check required environment variables
if ! aws sts get-caller-identity &>/dev/null; then
    echo "ERROR: AWS credentials not configured."
    exit 1
fi

echo "=== Destroying Lambda config refresher ==="
cd infra/lambda-config-refresh
terraform destroy -auto-approve

echo "=== Destroying service-2 ==="
cd ../service-2
terraform destroy -auto-approve

echo "=== Destroying service-1 ==="
cd ../service-1
terraform destroy -auto-approve

echo "=== Destroying SSM parameters (prod) ==="
cd ../config/prod
terraform destroy -auto-approve

echo "=== Destroying SSM parameters (dev) ==="
cd ../dev
terraform destroy -auto-approve

echo "=== Destroying platform (VPC, ALB, ECS Cluster) ==="
cd ../../platform
terraform destroy -auto-approve

echo "=== Destroy complete ==="
