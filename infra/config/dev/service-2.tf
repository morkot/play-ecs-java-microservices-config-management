# Service-2 parameters for dev environment
# These override common and env-wide parameters

locals {
  service_2_params = {
    # Example: override for service-2 only in dev
    # "service-2/app/log/level" = "TRACE"
  }
}
