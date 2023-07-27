resource "aws_sns_topic" "scaleup" {
  name = var.name
}

resource "aws_sns_topic_subscription" "scaleup" {
  topic_arn = aws_sns_topic.scaleup.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scaleup.arn
}