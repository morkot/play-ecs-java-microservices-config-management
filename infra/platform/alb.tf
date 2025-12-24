# Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-alb-sg"
    Environment = var.environment
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target Group for Service 1
resource "aws_lb_target_group" "service1" {
  name        = "${var.project_name}-svc1-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/service-1/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-svc1-tg"
    Environment = var.environment
  }
}

# Target Group for Service 2
resource "aws_lb_target_group" "service2" {
  name        = "${var.project_name}-svc2-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/service-2/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-svc2-tg"
    Environment = var.environment
  }
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No route matched"
      status_code  = "404"
    }
  }

  tags = {
    Name = "${var.project_name}-http-listener"
  }
}

# ALB Listener Rule for Service 1 (path-based routing)
resource "aws_lb_listener_rule" "service1" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service1.arn
  }

  condition {
    path_pattern {
      values = ["/service-1/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-svc1-rule"
  }
}

# ALB Listener Rule for Service 2 (path-based routing)
resource "aws_lb_listener_rule" "service2" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service2.arn
  }

  condition {
    path_pattern {
      values = ["/service-2/*"]
    }
  }

  tags = {
    Name = "${var.project_name}-svc2-rule"
  }
}

# SSM Parameter to store ALB endpoint for use by other modules
resource "aws_ssm_parameter" "alb_endpoint" {
  name        = "/${var.project_name}/platform/alb-endpoint"
  description = "ALB endpoint URL for the ECS config demo"
  type        = "String"
  value       = "http://${aws_lb.main.dns_name}"

  tags = {
    Name        = "${var.project_name}-alb-endpoint"
    Environment = var.environment
  }
}
