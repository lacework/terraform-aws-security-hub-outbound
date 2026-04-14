output "event_bus_arn" {
  description = "ARN of the custom EventBridge bus that receives Lacework events."
  value       = module.security_hub_outbound.event_bus_arn
}

output "event_bus_name" {
  description = "Name of the custom EventBridge bus."
  value       = module.security_hub_outbound.event_bus_name
}

output "event_rule_arn" {
  description = "ARN of the EventBridge rule that forwards Lacework events to SQS."
  value       = module.security_hub_outbound.event_rule_arn
}

output "sqs_queue_arn" {
  description = "ARN of the SQS queue buffering events for the Lambda."
  value       = module.security_hub_outbound.sqs_queue_arn
}

output "sqs_queue_url" {
  description = "URL of the SQS queue buffering events for the Lambda."
  value       = module.security_hub_outbound.sqs_queue_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function that transforms events and publishes to Security Hub."
  value       = module.security_hub_outbound.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function."
  value       = module.security_hub_outbound.lambda_function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role the Lambda assumes."
  value       = module.security_hub_outbound.lambda_role_arn
}

output "lacework_alert_channel_id" {
  description = "ID of the Lacework CloudWatch alert channel created by the module."
  value       = module.security_hub_outbound.lacework_alert_channel_id
}

output "lacework_alert_rule_id" {
  description = "ID of the Lacework alert rule created by the module."
  value       = module.security_hub_outbound.lacework_alert_rule_id
}
