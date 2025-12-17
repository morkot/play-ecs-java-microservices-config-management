# Read ALB endpoint from SSM Parameter (created by platform module)
data "aws_ssm_parameter" "alb_endpoint" {
  name = "/${var.project_name}/platform/alb-endpoint"
}

# Archive the Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda-config-refresh.zip"
}

# Lambda function
resource "aws_lambda_function" "config_refresh" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${var.project_name}-config-refresh"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory

  environment {
    variables = {
      ALB_ENDPOINT = data.aws_ssm_parameter.alb_endpoint.value
    }
  }

  tags = {
    Name        = "${var.project_name}-config-refresh"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.config_refresh.function_name}"
  retention_in_days = 14

  tags = {
    Name        = "${var.project_name}-config-refresh-logs"
    Environment = var.environment
  }
}
