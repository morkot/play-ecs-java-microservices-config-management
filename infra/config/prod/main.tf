// Prod environment configuration
// TODO: Add s3-bucket.tf and s3_env_files module when ready to deploy prod

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

locals {
  project_name = "ecs-config-demo"
  environment  = "prod"
}

// Load common defaults
module "common" {
  source = "../common"
}

// Merge all service params from this directory
locals {
  env_service_params = merge(
    local.service_1_params,
    local.service_2_params,
  )
}

// TODO: Uncomment when s3-bucket.tf is added
// module "s3_env_files" {
//   source = "../modules/s3-env-file"
//
//   environment  = local.environment
//   project_name = local.project_name
//   services     = local.services
//   s3_bucket_id = aws_s3_bucket.config.id
//
//   common_params         = module.common.common_params
//   common_service_params = module.common.service_params
//   env_params            = local.env_params
//   env_service_params    = local.env_service_params
// }
