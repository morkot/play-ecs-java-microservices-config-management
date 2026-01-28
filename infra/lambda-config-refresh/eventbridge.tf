# EventBridge Rule for S3 config file changes
# Triggers when .env files are created/modified in the config bucket

data "aws_caller_identity" "current" {}

locals {
  config_bucket_name = var.config_bucket_name != "" ? var.config_bucket_name : "${var.project_name}-${var.environment}-config-${data.aws_caller_identity.current.account_id}"
}

resource "aws_cloudwatch_event_rule" "s3_config_change" {
  name        = "${var.project_name}-s3-config-change"
  description = "Capture S3 config file changes for ECS service refresh"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created", "Object Deleted"]
    detail = {
      bucket = {
        name = [local.config_bucket_name]
      }
      object = {
        key = [{
          suffix = ".env"
        }]
      }
    }
  })
}

# EventBridge Target - Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.s3_config_change.name
  target_id = "${var.project_name}-config-refresh-lambda"
  arn       = aws_lambda_function.config_refresh.arn
}

# Lambda permission to allow EventBridge to invoke the function
resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.config_refresh.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_config_change.arn
}
