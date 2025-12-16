# Get platform infrastructure outputs from remote state
data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "../platform/terraform.tfstate"
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}
