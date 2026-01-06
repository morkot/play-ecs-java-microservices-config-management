# ECS Java Microservices with Centralized Configuration Management

Managing configuration across multiple microservices quickly becomes painful:

- **Scattered property files** - Each service has its own `application.properties`, making it hard to see or change configuration across services
- **Redeployment required** - Changing a single property means rebuilding and redeploying the entire service
- **Environment drift** - Copy-paste errors lead to inconsistent configuration between dev, staging, and prod

This project is POC showing how these problems can be solved with **AWS SSM Parameter Store** and **automatic hot-reload**:

- **Single source of truth** - All configuration in one place, organized by environment and service
- **Instant updates** - Change a parameter and services reload within seconds, no redeployment needed
- **Terraform-managed** - Infrastructure-as-code with clear separation of common vs environment-specific settings. We can have predefined hirerachy when
environment configuration overrides common default values.
- **Full audit trail** - AWS CloudTrail tracks every parameter change

![Architecture](architecture.png)

## Architecture

- **2 Spring Boot microservices** running on ECS Fargate
- **SSM Parameter Store** for centralized configuration (Terraform-managed)
- **EventBridge** watches for parameter changes
- **Lambda** triggers config refresh on the affected service
- **ALB** routes traffic based on path prefix
- **Spring Profiles** for environment-specific configuration

For demonstration purposes:

- **service-1** runs with `dev` profile
- **service-2** runs with `prod` profile

## SSM Parameter Structure

Parameters are organized by environment and service:

```
/ecs-config-demo/
├── dev/
│   ├── service-1/
│   │   └── app/
│   │       ├── name
│   │       ├── version
│   │       ├── environment
│   │       ├── feature/flag
│   │       └── log/level
│   └── service-2/
│       └── app/...
└── prod/
    ├── service-1/
    │   └── app/...
    └── service-2/
        └── app/...
```

Parameters are automatically converted to Spring properties:

| SSM Parameter Name                                  | Spring Property Name  |
|-----------------------------------------------------|-----------------------|
| `/ecs-config-demo/dev/service-1/app/feature/flag`   | `app.feature.flag`    |
| `/ecs-config-demo/dev/service-1/app/environment`    | `app.environment`     |
| `/ecs-config-demo/prod/service-2/app/log/level`     | `app.log.level`       |

## Configuration Management

Parameters are managed via Terraform in `infra/config/`:

```
infra/config/
├── main.tf           # Creates all SSM parameters
├── common/           # Shared parameters (all environments)
│   └── parameters.tf
├── dev/              # Dev-specific overrides
│   └── parameters.tf
└── prod/             # Prod-specific overrides
    └── parameters.tf
```

- **Common parameters** define defaults for all environments
- **Environment parameters** override common values
- All environments are applied in a single `terraform apply`

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

# Deploy SSM parameters (all environments)
cd ../config
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

# View service-1 config (dev environment)
curl -s http://$ALB/service-1/api/config | jq

# View service-2 config (prod environment)
curl -s http://$ALB/service-2/api/config | jq
```

Notice the differences:

- **service-1 (dev)**: `feature.flag=true`, `log.level=DEBUG`
- **service-2 (prod)**: `feature.flag=false`, `log.level=INFO`

### Step 2: View SSM Properties

```bash
# See all SSM properties loaded by each service
curl -s http://$ALB/service-1/api/ssm-properties | jq
curl -s http://$ALB/service-2/api/ssm-properties | jq
```

### Step 3: Watch Automatic Refresh

Open two terminals:

**Terminal 1 - Watch service-1:**

```bash
while true; do
  echo "=== $(date) ==="
  curl -s http://$ALB/service-1/api/ssm-properties | jq
  sleep 2
done
```

**Terminal 2 - Change a parameter:**

```bash
aws ssm put-parameter \
  --name "/ecs-config-demo/dev/service-1/app/feature/flag" \
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

### Step 4: Add Custom Properties Dynamically

```bash
# Add any custom property - no code change needed!
aws ssm put-parameter \
  --name "/ecs-config-demo/dev/service-1/custom/my-setting" \
  --value "hello-world" \
  --type String \
  --overwrite

# Wait a few seconds, then check
curl -s http://$ALB/service-1/api/ssm-properties | jq
# Shows: {"custom/my-setting": "hello-world", ...}
```

### Step 5: Update Configuration via Terraform

For persistent changes, update the Terraform config:

```bash
# Edit infra/config/dev/parameters.tf to change values
# Then apply:
cd infra/config
terraform apply
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
cd ../config && terraform destroy
cd ../platform && terraform destroy
```
