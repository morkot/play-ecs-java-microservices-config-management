# EventBridge Rule for SSM Parameter Store changes
resource "aws_cloudwatch_event_rule" "ssm_parameter_change" {
  name        = "${var.project_name}-ssm-parameter-change"
  description = "Capture SSM Parameter Store changes for config refresh"

  event_pattern = jsonencode({
    source      = ["aws.ssm"]
    detail-type = ["Parameter Store Change"]
    detail = {
      name = [{
        prefix = var.ssm_parameter_prefix
      }]
      operation = ["Create", "Update", "Delete"]
    }
  })

  tags = {
    Name        = "${var.project_name}-ssm-parameter-change"
    Environment = var.environment
  }
}

# EventBridge Target - Lambda function
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.ssm_parameter_change.name
  target_id = "${var.project_name}-config-refresh-lambda"
  arn       = aws_lambda_function.config_refresh.arn
}

# Lambda permission to allow EventBridge to invoke the function
resource "aws_lambda_permission" "eventbridge_invoke" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.config_refresh.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ssm_parameter_change.arn
}
