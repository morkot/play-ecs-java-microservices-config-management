variable "project_name" {
  description = "Project name"
  type        = string
  default     = "ecs-config-demo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "ssm_parameter_prefix" {
  description = "SSM parameter path prefix to monitor for changes"
  type        = string
  default     = "/ecs-config-demo/"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "lambda_memory" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}
