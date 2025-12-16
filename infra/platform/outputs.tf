# 01-network/outputs.tf
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB zone ID"
  value       = aws_lb.main.zone_id
}

output "properties_target_group_arn" {
  description = "Properties target group ARN"
  value       = aws_lb_target_group.properties.arn
}

output "ssm_target_group_arn" {
  description = "SSM target group ARN"
  value       = aws_lb_target_group.ssm.arn
}

output "cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "alb_endpoint" {
  description = "ALB endpoint for testing"
  value       = "http://${aws_lb.main.dns_name}"
}

output "test_urls" {
  description = "URLs to test the services"
  value = {
    properties = "http://${aws_lb.main.dns_name}/api/config"
    ssm        = "http://${aws_lb.main.dns_name}/api/ssm"
  }
}
