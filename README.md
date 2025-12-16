# play-ecs-java-microservices-config-management
Everything to build and play with centralaised configuration management in ecs and java µservices

## Prepare and deploy

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





## Demo Flow

  ### 1. Check current config

  curl http://ecs-config-demo-alb-136450583.eu-west-1.elb.amazonaws.com/api/config

  ### 2. Update a parameter in AWS SSM (e.g., via console or CLI)

  aws ssm put-parameter --name "/ecs-config-demo/app/feature/flag" --value "true" --overwrite

  ### 3. Trigger hot reload (no restart needed!)

  curl -X POST http://ecs-config-demo-alb-136450583.eu-west-1.elb.amazonaws.com/api/config/refresh

  ### 4. Verify new config is active

  curl http://ecs-config-demo-alb-136450583.eu-west-1.elb.amazonaws.com/api/config

  The refresh response will look like:
  {
    "success": true,
    "message": "Configuration refreshed from SSM",
    "parameterCount": 5,
    "refreshTime": "2025-12-16T10:30:00Z"
  }
