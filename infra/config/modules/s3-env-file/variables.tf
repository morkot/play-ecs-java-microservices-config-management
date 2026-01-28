// Input variables for S3 environment file module

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for bucket naming"
  type        = string
  default     = "ecs-config-demo"
}

variable "services" {
  description = "List of services in this environment"
  type        = list(string)
}

variable "s3_bucket_id" {
  description = "S3 bucket ID where env files will be stored"
  type        = string
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
