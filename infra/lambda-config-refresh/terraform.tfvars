# terraform.tfvars for lambda-config-refresh

project_name   = "ecs-config-demo"
environment    = "dev"
lambda_timeout = 60
lambda_memory  = 128

# config_bucket_name is auto-constructed as: {project_name}-{environment}-config-{account_id}
# Uncomment to override:
# config_bucket_name = "my-custom-bucket-name"
