# CloudWatch Log Group for ECS Service
resource "aws_cloudwatch_log_group" "ecs_service" {
  name              = "/ecs/${var.project_name}/${var.service_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.service_name}-logs"
    Environment = var.environment
  }
}
