# Security Group for ECS Service
resource "aws_security_group" "ecs_service" {
  name        = "${var.project_name}-${var.service_name}-sg"
  description = "Security group for ${var.service_name} ECS service"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.platform.outputs.alb_security_group_id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.service_name}-sg"
    Environment = var.environment
  }
}
