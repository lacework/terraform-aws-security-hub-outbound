output "event_bus_arn" {
  description = "ARN of the custom EventBridge bus that receives Lacework events."
  value       = aws_cloudwatch_event_bus.lacework.arn
}

output "event_bus_name" {
  description = "Name of the custom EventBridge bus."
  value       = aws_cloudwatch_event_bus.lacework.name
}

output "event_rule_arn" {
  description = "ARN of the EventBridge rule that forwards Lacework events to SQS."
  value       = aws_cloudwatch_event_rule.lacework.arn
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue buffering events for the Lambda."
  value       = aws_sqs_queue.events.arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue buffering events for the Lambda."
  value       = aws_sqs_queue.events.id
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that transforms events and publishes to Security Hub."
  value       = aws_lambda_function.integration.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.integration.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role the Lambda assumes."
  value       = aws_iam_role.lambda.arn
}

output "lacework_alert_channel_id" {
  description = "ID of the Lacework CloudWatch alert channel created by the module."
  value       = lacework_alert_channel_aws_cloudwatch.this.id
}

output "lacework_alert_rule_id" {
  description = "ID of the Lacework alert rule created by the module."
  value       = lacework_alert_rule.this.id
}
