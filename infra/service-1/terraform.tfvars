# Example terraform.tfvars file
# Copy this file to terraform.tfvars and update with your values

project_name    = "ecs-config-demo"
environment     = "dev"
service_name    = "service-1"
container_port  = 8080
container_cpu   = 256
container_memory = 512
desired_count   = 1

# Replace with your ECR image URI
container_image = "314146335982.dkr.ecr.eu-west-1.amazonaws.com/service-1"
