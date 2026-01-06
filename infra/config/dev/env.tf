# Dev environment-wide parameters
# These apply to ALL services in dev environment
# Keys should NOT include service prefix

locals {
  # Services deployed in dev
  services = ["service-1", "service-2"]

  env_params = {
    "app/log/level"    = "DEBUG"
    "app/feature/flag" = "true"
    "app/environment"  = "dev"
  }
}
