// Dev environment configuration
// Uses S3 env files for configuration

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

// Create S3 environment files
module "s3_env_files" {
  source = "../modules/s3-env-file"

  environment  = local.environment
  project_name = local.project_name
  services     = local.services
  s3_bucket_id = aws_s3_bucket.config.id

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

// S3 env file outputs
output "env_file_arns" {
  description = "ARNs of the S3 env files"
  value       = module.s3_env_files.env_file_arns
}

output "env_file_contents" {
  description = "Contents of the generated .env files (for debugging)"
  value       = module.s3_env_files.env_file_contents
  sensitive   = true
}
