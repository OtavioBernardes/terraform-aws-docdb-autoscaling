# Lambda function logs
resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
}

locals {
  scaleup_name = "scaleup"
  scaledown_name = "scaledown"
}

# Scale-up alarm
resource "aws_cloudwatch_metric_alarm" "scaleup" {
  count = length(var.scaling_policy)

  alarm_name          = "${var.name}-${local.scaleup_name}-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/DocDB"
  metric_name         = "${var.scaling_policy.metric_name}-${local.scaleup_name}"
  statistic           = var.scaling_policy.statistic
  period              = tostring(var.scaling_policy.cooldown)
  threshold           = tostring(var.scaling_policy.target)

  # Actions
  actions_enabled = "true"
  alarm_actions   = [aws_sns_topic.main.arn]

  dimensions = {
    DBClusterIdentifier = var.cluster_identifier
  }
}

# Scale-down alarm
# resource "aws_cloudwatch_metric_alarm" "scaledown" {
#   count = length(var.scaling_policy)

#   alarm_name          = "${var.name}-${local.scaledown_name}-${count.index}"
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
