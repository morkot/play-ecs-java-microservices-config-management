# SSM Parameters Module
# Merges parameters and creates SSM resources
#
# Merge hierarchy (later overrides earlier):
#   1. Common env-wide - defaults for all services in all envs
#   2. Common service-specific - defaults for specific service in all envs
#   3. Environment env-wide - overrides for all services in this env
#   4. Environment service-specific - overrides for specific service in this env

locals {
  # Build parameters for each service
  # Merge order: common env-wide -> common service -> env env-wide -> env service
  all_parameters = merge(flatten([
    for service in var.services : {
      for key, value in merge(
        # 1. Common env-wide parameters (add service prefix)
        { for k, v in var.common_params : "${service}/${k}" => v },
        # 2. Common service-specific parameters
        { for k, v in var.common_service_params : k => v if startswith(k, "${service}/") },
        # 3. Environment env-wide parameters (add service prefix)
        { for k, v in var.env_params : "${service}/${k}" => v },
        # 4. Environment service-specific parameters
        { for k, v in var.env_service_params : k => v if startswith(k, "${service}/") }
      ) :
      "/${var.project_name}/${var.environment}/${key}" => value
    }
  ])...)
}

# Create SSM parameters
resource "aws_ssm_parameter" "config" {
  for_each = local.all_parameters

  name        = each.key
  description = "Managed by Terraform"
  type        = "String"
  value       = each.value

  tags = {
    ManagedBy   = "terraform"
    Environment = var.environment
  }
}

output "parameters" {
  description = "All SSM parameters created"
  value       = { for k, v in aws_ssm_parameter.config : k => v.value }
  sensitive   = true
}

output "parameter_count" {
  description = "Number of parameters created"
  value       = length(aws_ssm_parameter.config)
}
