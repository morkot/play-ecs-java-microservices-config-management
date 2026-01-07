# Read platform state to get ECS cluster name
data "terraform_remote_state" "platform" {
  backend = "local"

  config = {
    path = "${path.module}/../platform/terraform.tfstate"
  }
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
      ECS_CLUSTER_NAME = data.terraform_remote_state.platform.outputs.cluster_name
      PROJECT_NAME     = var.project_name
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
