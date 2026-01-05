# Prod environment parameters
# These override common parameters for prod environment

locals {
  parameters = {
    # Service 1 - prod specific
    "service-1/app/environment"    = "production"
    "service-1/app/feature/flag"   = "false"

    # Service 2 - prod specific
    "service-2/app/environment"    = "production"
    "service-2/app/feature/flag"   = "false"
  }
}

output "parameters" {
  value = local.parameters
}
