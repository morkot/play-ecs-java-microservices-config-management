// Prod environment-wide parameters
// These apply to ALL services in prod environment
// Keys should NOT include service prefix

locals {
  services = ["service-1", "service-2"]

  env_params = {
    "app/log/level"    = "INFO"
    "app/feature/flag" = "false"
    "app/environment"  = "production"
  }
}
