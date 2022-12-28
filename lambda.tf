# Scaleup Lambda function
resource "aws_lambda_function" "scaleup" {
  filename         = local.output_path
  function_name    = "${var.name}-scaleup"
  role             = aws_iam_role.lambda.arn
  handler          = "index.scaleup"
  source_code_hash = data.archive_file.source_code.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      min_capacity       = tostring(var.min_capacity)
      max_capacity       = tostring(var.max_capacity)
      cluster_identifier = var.cluster_identifier

      metric_name        = var.scaling_policy.metric_name
      target             = tostring(var.scaling_policy.target)
      scaledown_target   = tostring(var.scaling_policy.scaledown_target)
      statistic          = var.scaling_policy.statistic
      cooldown           = tostring(var.scaling_policy.cooldown)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.main,
    data.archive_file.source_code
  ]
}

resource "aws_lambda_permission" "sns" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scaleup.arn
  principal     = "sns.amazonaws.com"
  statement_id  = "AllowSubscriptionToSNS"
  source_arn    = aws_sns_topic.main.arn
}

# Scaledown Lambda function
resource "aws_lambda_function" "scaledown" {
  filename         = local.output_path
  function_name    = "${var.name}-scaledown"
  role             = aws_iam_role.lambda.arn
  handler          = "index.scaledown"
  source_code_hash = data.archive_file.source_code.output_base64sha256
  runtime          = "python3.9"

  environment {
    variables = {
      min_capacity       = tostring(var.min_capacity)
      max_capacity       = tostring(var.max_capacity)
      cluster_identifier = var.cluster_identifier

      metric_name        = var.scaling_policy.metric_name
      target             = tostring(var.scaling_policy.target)
      scaledown_target   = tostring(var.scaling_policy.scaledown_target)
      statistic          = var.scaling_policy.statistic

      period             = tostring(var.scaling_policy.period)
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.main,
    data.archive_file.source_code
  ]
}

resource "aws_cloudwatch_event_rule" "scaledown" {
    name = "schedule"
    description = "Schedule for DocDB ${var.cluster_identifier} scaledown function"
    schedule_expression = "cron(0 * * * *)"
}

resource "aws_cloudwatch_event_target" "scaledown" {
    rule = aws_cloudwatch_event_rule.scaledown.name
    target_id = "Scaledown DocDB ${var.cluster_identifier}"
    arn = aws_lambda_function.scaledown.arn
}


resource "aws_lambda_permission" "scaledown" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.scaledown.function_name
    principal = "events.amazonaws.com"
}
