// Outputs for common module

output "common_params" {
  description = "Common env-wide parameters"
  value = merge(
    local.common_params,
    local.common_jvm_params,
  )
}

output "service_params" {
  description = "Common service-specific parameters"
  value = merge(
    local.service_1_params,
    local.service_2_params,
  )
}
