# Service-1 parameters for dev environment
# These override common and env-wide parameters

locals {
  service_1_params = {
    # Example: override for service-1 only in dev
    # "service-1/app/log/level" = "TRACE"
  }
}
