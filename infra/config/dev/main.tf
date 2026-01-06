// Dev environment SSM parameters

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

// Load common defaults
module "common" {
  source = "../common"
}

// Create SSM parameters
module "ssm_params" {
  source = "../modules/ssm-params"

  environment = "dev"
  services    = local.services

  common_params         = module.common.common_params
  common_service_params = module.common.service_params
  env_params            = local.env_params
  env_service_params    = local.env_service_params
}

// Merge all service params from this directory
locals {
  env_service_params = merge(
    local.service_1_params,
    local.service_2_params,
  )
}

output "parameters" {
  value     = module.ssm_params.parameters
  sensitive = true
}

output "parameter_count" {
  value = module.ssm_params.parameter_count
}
