# Service-1 parameters for prod environment
# These override common and env-wide parameters

locals {
  service_1_params = {
    # Example: override for service-1 only in prod
    # "service-1/app/log/level" = "WARN"
  }
}
