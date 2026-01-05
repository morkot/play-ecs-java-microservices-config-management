# Dev environment parameters
# These override common parameters for dev environment

locals {
  parameters = {
    # Service 1 - dev specific
    "service-1/app/environment"    = "dev"
    "service-1/app/feature/flag"   = "true"
    "service-1/app/log/level"      = "DEBUG"

    # Service 2 - dev specific
    "service-2/app/environment"    = "dev"
    "service-2/app/feature/flag"   = "true"
    "service-2/app/log/level"      = "DEBUG"
  }
}

output "parameters" {
  value = local.parameters
}
