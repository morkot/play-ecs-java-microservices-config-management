# Service-1 default parameters
# These apply to service-1 in ALL environments

locals {
  service_1_params = {
    "service-1/app/name"    = "ecs-config-demo"
    "service-1/app/version" = "1.0.0"
  }
}
