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

variable "config_bucket_name" {
  description = "S3 bucket name for config files to monitor for changes. If not provided, will be constructed as {project_name}-{environment}-config-{account_id}"
  type        = string
  default     = ""
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
