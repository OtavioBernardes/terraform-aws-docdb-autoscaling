locals {
  scaleup_name = "scaleup"
  scaledown_name = "scaledown"
}

# Lambda function logs
resource "aws_cloudwatch_log_group" "scaleup" {
  name              = "/aws/lambda/${var.name}-${local.scaleup_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "scaledown" {
  name              = "/aws/lambda/${var.name}-${local.scaledown_name}"
  retention_in_days = 7
}

# Scale-up alarm
resource "aws_cloudwatch_metric_alarm" "scaleup" {
  alarm_name          = "${var.name}-${local.scaleup_name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/DocDB"
  metric_name         = "${var.scaling_policy.metric_name}-${local.scaleup_name}"
  statistic           = var.scaling_policy.statistic
  period              = tostring(var.scaling_policy.cooldown)
  threshold           = tostring(var.scaling_policy.target)

  # Actions
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.scaleup.arn]

  dimensions = {
    DBClusterIdentifier = var.cluster_identifier
  }
}

# Scale-down alarm
# resource "aws_cloudwatch_metric_alarm" "scaledown" {
#   alarm_name          = "${var.name}-${local.scaledown_name}"
#   comparison_operator = "LessThanThreshold"
#   evaluation_periods  = "1"
#   namespace           = "AWS/DocDB"
#   metric_name         = "${var.scaling_policy.metric_name}-${local.scaledown_name}"
#   statistic           = var.scaling_policy.statistic
#   period              = tostring(var.scaling_policy.cooldown)
#   threshold           = tostring(var.scaling_policy.scaledown_target)

#   # Actions
#   actions_enabled = "true"
#   alarm_actions   = [aws_sns_topic.main.arn]

#   dimensions = {
#     DBClusterIdentifier = var.cluster_identifier
#   }
# }
