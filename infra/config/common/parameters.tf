# Common parameters applied to all environments
# These can be overridden by environment-specific parameters
# Note: Keys here don't include env prefix - it's added during merge

locals {
  parameters = {
    # Service 1 parameters
    "service-1/app/name"        = "ecs-config-demo"
    "service-1/app/version"     = "1.0.0"
    "service-1/app/log/level"   = "INFO"

    # Service 2 parameters
    "service-2/app/name"        = "service-2"
    "service-2/app/version"     = "1.0.0"
    "service-2/app/log/level"   = "INFO"
  }
}

output "parameters" {
  value = local.parameters
}
