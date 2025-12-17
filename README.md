# play-ecs-java-microservices-config-management
Everything to build and play with centralaised configuration management in ecs and java µservices

## Prepare and deploy

### Build app and docker image

```shell
cd app/ service-1
mvn clean package -DskipTests
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com
docker build -t AWS_ACCOUNT.dkr.ecr.eu-west-1.amazonaws.com/service-1 .

aws ssm put-parameter \
  --name "/ecs-config-demo/app/feature/flag" \
  --value "true" \
  --type String \
  --overwrite

curl -X POST http://ecs-config-demo-alb-136450583.eu-west-1.elb.amazonaws.com/api/config/refresh
```

About ssm maping to properties:
```
Your app config (application.properties):
  app.config.ssm.path=/ecs-config-demo/

  Path transformation:
  SSM Parameter Name                        →  Spring Property Name
  ─────────────────────────────────────────────────────────────────
  /ecs-config-demo/app/environment          →  app.environment
  /ecs-config-demo/app/feature/flag         →  app.feature.flag
  /ecs-config-demo/db/host                  →  db.host

  The code strips the prefix (/ecs-config-demo/) and converts / to .
```

### Deploy platform, services and `lambda-config-refresher`

```shell
cd infra/platform
terraform init && terraform apply

cd infra/service-1
terraform init && terraform apply

cd infra/lambda-config-refresher
terraform init && terraform apply
```

## Demo

1. Get service URL

```shell
cd infra/platform
terraform output
```

2. Demonstrate properties via broser or via curl by going to test_urls.properties
3. Demonstrate automated refresh:

```shell
while true; do curl -s http://ecs-config-demo-alb-1058709648.eu-west-1.elb.amazonaws.com/api/config | jq '.application.featureFlag'; sleep 1; done
```

Go to SSM parameter store and change value of `/ecs-config-demo/app/feature/flag`

Switch back to terminal and see new value appear after few seconds.
