# SSM Parameter Configuration Management
# Creates parameters for all environments at once
# Common parameters are merged with environment-specific overrides

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}

# Load common parameters
module "common" {
  source = "./common"
}

# Load dev parameters
module "dev" {
  source = "./dev"
}

# Load prod parameters
module "prod" {
  source = "./prod"
}

locals {
  # Map of all environment modules
  env_modules = {
    dev  = module.dev.parameters
    prod = module.prod.parameters
  }

  # Merge common with each environment (env overrides common)
  # Then add /ecs-config-demo/{env}/ prefix to each key
  all_parameters = merge([
    for env, params in local.env_modules : {
      for key, value in merge(module.common.parameters, params) :
      "/ecs-config-demo/${env}/${key}" => value
    }
  ]...)
}

# Create SSM parameters for all environments
resource "aws_ssm_parameter" "config" {
  for_each = local.all_parameters

  name        = each.key
  description = "Managed by Terraform"
  type        = "String"
  value       = each.value

  tags = {
    ManagedBy = "terraform"
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
