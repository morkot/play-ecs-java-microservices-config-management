# Common env-wide parameters
# These apply to ALL services in ALL environments
# Keys should NOT include service prefix

locals {
  common_params = {
    "app/log/level" = "INFO"
  }
}
