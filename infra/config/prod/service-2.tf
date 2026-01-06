# Service-2 parameters for prod environment
# These override common and env-wide parameters

locals {
  service_2_params = {
    # Example: override for service-2 only in prod
    # "service-2/app/log/level" = "WARN"
  }
}
