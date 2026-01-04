# ECS Java Microservices with Centralized Configuration Management

This project demonstrates centralized configuration management for Java microservices running on AWS ECS, using SSM Parameter Store with automatic hot-reload via EventBridge and Lambda.

![Architecture](architecture.png)

## Architecture

- **2 Spring Boot microservices** running on ECS Fargate
- **SSM Parameter Store** for centralized configuration
- **EventBridge** watches for parameter changes
- **Lambda** triggers config refresh on the affected service
- **ALB** routes traffic based on path prefix

## SSM Parameter Structure

Each service reads from its own SSM path prefix:

```
/ecs-config-demo/
├── service-1/
│   └── app/
│       ├── feature/flag
│       └── environment
└── service-2/
    └── app/
        ├── feature/flag
        └── environment
```

Parameters are automatically converted to Spring properties:

| SSM Parameter Name                              | Spring Property Name  |
|-------------------------------------------------|-----------------------|
| `/ecs-config-demo/service-1/app/feature/flag`   | `app.feature.flag`    |
| `/ecs-config-demo/service-1/app/environment`    | `app.environment`     |
| `/ecs-config-demo/service-2/db/host`            | `db.host`             |

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- Java 21
- Maven
- Docker

## Deploy

### 1. Build Framework and Services

```bash
# Build shared framework
cd app/framework
mvn clean install

# Build services
cd ../service-1
mvn clean package -DskipTests

cd ../service-2
mvn clean package -DskipTests
```

### 2. Push Docker Images

```bash
export AWS_REGION=eu-west-1
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)

# Login to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push service-1
cd app/service-1
docker build -t $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-1 .
docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-1

# Build and push service-2
cd ../service-2
docker build -t $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-2 .
docker push $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com/service-2
```

### 3. Deploy Infrastructure

```bash
# Deploy platform (VPC, ALB, ECS Cluster)
cd infra/platform
terraform init && terraform apply

# Deploy services
cd ../service-1
terraform init && terraform apply

cd ../service-2
terraform init && terraform apply

# Deploy Lambda config refresher
cd ../lambda-config-refresh
terraform init && terraform apply
```

### 4. Get ALB Endpoint

```bash
cd infra/platform
terraform output alb_endpoint
```

## Demo: Automatic Configuration Refresh

### Step 1: View Current Configuration

```bash
ALB=<your-alb-dns>

# View service-1 config
curl -s http://$ALB/service-1/api/config | jq

# View service-2 config
curl -s http://$ALB/service-2/api/config | jq
```

### Step 2: Create SSM Parameters

```bash
# Create parameters for service-1
aws ssm put-parameter \
  --name "/ecs-config-demo/service-1/app/feature/flag" \
  --value "true" \
  --type String \
  --overwrite

aws ssm put-parameter \
  --name "/ecs-config-demo/service-1/app/environment" \
  --value "production" \
  --type String \
  --overwrite

# Create parameters for service-2
aws ssm put-parameter \
  --name "/ecs-config-demo/service-2/app/feature/flag" \
  --value "false" \
  --type String \
  --overwrite

aws ssm put-parameter \
  --name "/ecs-config-demo/service-2/app/environment" \
  --value "staging" \
  --type String \
  --overwrite
```

### Step 3: Watch Automatic Refresh

Open two terminals:

**Terminal 1 - Watch service-1:**
```bash
while true; do
  echo "=== $(date) ==="
  curl -s http://$ALB/service-1/api/config | jq '.application'
  sleep 2
done
```

**Terminal 2 - Change a parameter:**
```bash
aws ssm put-parameter \
  --name "/ecs-config-demo/service-1/app/feature/flag" \
  --value "false" \
  --type String \
  --overwrite
```

Within a few seconds, Terminal 1 will show the updated value. The flow is:

1. SSM Parameter changes
2. EventBridge detects the change
3. Lambda is triggered
4. Lambda calls `/service-1/api/config/refresh`
5. Service reloads configuration from SSM

### Step 4: View All SSM Properties

```bash
# See all dynamically loaded SSM properties
curl -s http://$ALB/service-1/api/ssm-properties | jq
curl -s http://$ALB/service-2/api/ssm-properties | jq
```

### Step 5: Add Custom Properties Dynamically

```bash
# Add any custom property - no code change needed!
aws ssm put-parameter \
  --name "/ecs-config-demo/service-1/custom/my-setting" \
  --value "hello-world" \
  --type String \
  --overwrite

# Wait a few seconds, then check
curl -s http://$ALB/service-1/api/ssm-properties | jq
# Shows: {"custom.my-setting": "hello-world", ...}
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /service-1/api/config` | View service-1 configuration |
| `GET /service-2/api/config` | View service-2 configuration |
| `GET /service-{n}/api/ssm-properties` | View all SSM-loaded properties |
| `POST /service-{n}/api/config/refresh` | Manually trigger config refresh |
| `GET /service-{n}/api/health` | Health check |

## Manual Refresh

If needed, you can manually trigger a refresh:

```bash
curl -X POST http://$ALB/service-1/api/config/refresh | jq
curl -X POST http://$ALB/service-2/api/config/refresh | jq
```

## Cleanup

```bash
cd infra/lambda-config-refresh && terraform destroy
cd ../service-2 && terraform destroy
cd ../service-1 && terraform destroy
cd ../platform && terraform destroy
```
