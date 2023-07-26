resource "aws_sns_topic" "scaleup" {
  name = "${var.name}-scaleup"
}

resource "aws_sns_topic" "scaledown" {
  name = "${var.name}-scaledown"
}

resource "aws_sns_topic_subscription" "scaleup" {
  topic_arn = aws_sns_topic.scaleup.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scaleup.arn
}

resource "aws_sns_topic_subscription" "scaledown" {
  topic_arn = aws_sns_topic.scaledown.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.scaledown.arn
}