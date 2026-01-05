# Example terraform.tfvars for lambda-config-refresh
# Copy this file to terraform.tfvars and update values if needed

project_name         = "ecs-config-demo"
environment          = "dev"
ssm_parameter_prefix = "/ecs-config-demo/"
lambda_timeout       = 60
lambda_memory        = 128

# Note: ALB endpoint is automatically read from SSM parameter
# created by the platform module: /${project_name}/platform/alb-endpoint
