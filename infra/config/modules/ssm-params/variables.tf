// Input variables for SSM parameters module

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for SSM path prefix"
  type        = string
  default     = "ecs-config-demo"
}

variable "services" {
  description = "List of services in this environment"
  type        = list(string)
}

variable "common_params" {
  description = "Common env-wide parameters (no service prefix)"
  type        = map(string)
  default     = {}
}

variable "common_service_params" {
  description = "Common service-specific parameters (with service prefix)"
  type        = map(string)
  default     = {}
}

variable "env_params" {
  description = "Environment env-wide parameters (no service prefix)"
  type        = map(string)
  default     = {}
}

variable "env_service_params" {
  description = "Environment service-specific parameters (with service prefix)"
  type        = map(string)
  default     = {}
}
