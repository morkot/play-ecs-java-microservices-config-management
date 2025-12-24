output "service_name" {
  description = "ECS Service name"
  value       = aws_ecs_service.service.name
}

output "service_arn" {
  description = "ECS Service ARN"
  value       = aws_ecs_service.service.id
}

output "task_definition_arn" {
  description = "Task Definition ARN"
  value       = aws_ecs_task_definition.service.arn
}

output "task_execution_role_arn" {
  description = "Task Execution Role ARN"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "task_role_arn" {
  description = "Task Role ARN"
  value       = aws_iam_role.ecs_task.arn
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ecs_service.id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group name"
  value       = aws_cloudwatch_log_group.ecs_service.name
}
