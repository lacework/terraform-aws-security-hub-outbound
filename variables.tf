variable "lacework_url" {
  type        = string
  description = "Lacework account URL, e.g. \"account.lacework.net\" or \"org.sub.lacework.net\" for Lacework Organizations. Passed to the Lambda as the LACEWORK_INSTANCE environment variable."
  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?\\.lacework\\.net$", var.lacework_url))
    error_message = "lacework_url must be a full hostname ending in .lacework.net (e.g. \"account.lacework.net\" or \"org.sub.lacework.net\"). The hostname prefix must start and end with an alphanumeric character and may contain alphanumerics, dashes, and dots."
  }
}

variable "resource_prefix" {
  type        = string
  default     = "lw-sechub"
  description = "Prefix for all created AWS and Lacework resource names."
}

variable "default_aws_account_id" {
  type        = string
  default     = ""
  description = "AWS account ID that the Lambda maps unknown-source findings to. Defaults to the caller identity when empty."
}

variable "lacework_aws_account_id" {
  type        = string
  default     = "434813966438"
  description = "AWS account ID of the Lacework platform. Granted events:PutEvents on the custom EventBridge bus and used as the event_pattern account filter."
}

variable "customer_account_ids" {
  type        = list(string)
  default     = []
  description = "List of customer AWS account IDs that are configured in Lacework. Joined with var.lacework_aws_account_id to form the EventBridge rule's account filter, so events published from any of these accounts (e.g. \"aws events put-events\" for smoke tests) are forwarded to the Lambda in addition to those from Lacework's own account."
  validation {
    condition     = alltrue([for a in var.customer_account_ids : can(regex("^[0-9]{12}$", a))])
    error_message = "customer_account_ids entries must each be a 12-digit AWS account ID."
  }
}

variable "severities" {
  type        = list(string)
  default     = ["Critical", "High", "Medium", "Low", "Info"]
  description = "Lacework alert severities to forward to Security Hub."
  validation {
    condition     = alltrue([for s in var.severities : contains(["Critical", "High", "Medium", "Low", "Info"], s)])
    error_message = "severities entries must be one of: Critical, High, Medium, Low, Info."
  }
}

variable "alert_subcategories" {
  type        = list(string)
  default     = ["Compliance", "Application", "Cloud Activity", "File", "Machine", "User", "Platform", "Kubernetes Activity", "Registry", "SystemCall", "Host Vulnerability", "Container Vulnerability", "Threat Intel"]
  description = "Lacework alert subcategories attached to the alert rule."
}

variable "alert_channel_name" {
  type        = string
  default     = ""
  description = "Name for the Lacework CloudWatch alert channel. Defaults to \"<resource_prefix>-channel\" when empty."
}

variable "alert_rule_name" {
  type        = string
  default     = ""
  description = "Name for the Lacework alert rule. Defaults to \"<resource_prefix>-rule\" when empty."
}

variable "lambda_source_s3_bucket" {
  type        = string
  default     = "cloud-automation-templates-prod"
  description = "Source S3 bucket holding the published Lambda deployment zip. The module copies the object into a stack-local bucket in the consumer's region at apply time, because aws_lambda_function requires the code-source bucket to be in the same region as the function."
}

variable "lambda_source_s3_key" {
  type        = string
  default     = "aws/lacework-aws-security-hub-outbound/latest/lambda/events_processor.zip"
  description = "Source S3 object key for the Lambda deployment zip. Pin to a versioned key (e.g. \"aws/lacework-aws-security-hub-outbound/0.1.0/lambda/events_processor.zip\") to control updates; the \"latest\" key does not trigger redeploys automatically because aws_s3_object_copy is idempotent on the destination key."
}

variable "lambda_memory_size" {
  type        = number
  default     = 256
  description = "Memory (MB) allocated to the Lambda function."
}

variable "lambda_timeout" {
  type        = number
  default     = 30
  description = "Timeout (seconds) for the Lambda function."
}

variable "sqs_message_retention_seconds" {
  type        = number
  default     = 86400
  description = "Message retention period (seconds) on the SQS queue that buffers events for the Lambda."
}

variable "tags" {
  type        = map(string)
  default     = { ManagedBy = "terraform" }
  description = "Tags applied to all taggable resources."
}
