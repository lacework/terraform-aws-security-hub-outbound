data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  name_prefix          = var.resource_prefix
  default_account_id   = length(var.default_aws_account_id) > 0 ? var.default_aws_account_id : data.aws_caller_identity.current.account_id
  alert_channel_name   = length(var.alert_channel_name) > 0 ? var.alert_channel_name : "${local.name_prefix}-channel"
  alert_rule_name      = length(var.alert_rule_name) > 0 ? var.alert_rule_name : "${local.name_prefix}-rule"
  security_hub_arn     = "arn:aws:securityhub:${data.aws_region.current.region}::product/lacework/lacework"
  event_bus_name       = "${local.name_prefix}-event-bus"
  event_rule_name      = "${local.name_prefix}-event-rule"
  sqs_queue_name       = "${local.name_prefix}-event-queue"
  lambda_function_name = "${local.name_prefix}-integration"
  lambda_role_name     = "${local.name_prefix}-role"
}

# Stack-local bucket that holds the Lambda zip in the same region as the Lambda.
# aws_lambda_function requires the code-source S3 bucket to be in the function's region,
# and Lacework publishes the zip to a single us-west-2 bucket (cloud-automation-templates-prod),
# so we mirror the object into a per-module bucket at apply time.
resource "aws_s3_bucket" "lambda_source" {
  bucket_prefix = "${local.name_prefix}-lambda-"
  force_destroy = true
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "lambda_source" {
  bucket                  = aws_s3_bucket.lambda_source.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object_copy" "lambda_source" {
  bucket = aws_s3_bucket.lambda_source.id
  key    = var.lambda_source_s3_key
  source = "${var.lambda_source_s3_bucket}/${var.lambda_source_s3_key}"
}

# Lambda execution role
resource "aws_iam_role" "lambda" {
  name = local.lambda_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Managed policy: SQS read + CloudWatch Logs write
resource "aws_iam_role_policy_attachment" "lambda_sqs_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

# Inline policy: BatchImportFindings to the Lacework product ARN
resource "aws_iam_policy" "batch_import_findings" {
  name        = "${local.name_prefix}-batch-import-findings"
  description = "Allows the ${local.lambda_function_name} Lambda to post findings to Security Hub under the Lacework product ARN"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["securityhub:BatchImportFindings"]
        Resource = local.security_hub_arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_batch_import_findings" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.batch_import_findings.arn
}

# SQS queue buffering events for the Lambda
resource "aws_sqs_queue" "events" {
  name                      = local.sqs_queue_name
  delay_seconds             = 0
  message_retention_seconds = var.sqs_message_retention_seconds
  tags                      = var.tags
}

data "aws_iam_policy_document" "sqs_from_events" {
  statement {
    sid    = "AllowEventBridge"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.events.arn]
  }
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id
  policy    = data.aws_iam_policy_document.sqs_from_events.json
}

# Lambda function (code is mirrored from Lacework's public bucket into aws_s3_bucket.lambda_source above)
resource "aws_lambda_function" "integration" {
  function_name    = local.lambda_function_name
  description      = "Transforms Lacework events delivered via SQS into AWS Security Hub findings."
  role             = aws_iam_role.lambda.arn
  handler          = "bootstrap"
  runtime          = "provided.al2023"
  architectures    = ["x86_64"]
  memory_size      = var.lambda_memory_size
  timeout          = var.lambda_timeout
  s3_bucket        = aws_s3_object_copy.lambda_source.bucket
  s3_key           = aws_s3_object_copy.lambda_source.key
  source_code_hash = aws_s3_object_copy.lambda_source.etag
  tags             = var.tags

  environment {
    variables = {
      DEFAULT_AWS_ACCOUNT = local.default_account_id
      LACEWORK_INSTANCE   = var.lacework_url
    }
  }

  depends_on = [aws_sqs_queue.events]
}

resource "aws_lambda_event_source_mapping" "sqs_to_lambda" {
  event_source_arn = aws_sqs_queue.events.arn
  function_name    = aws_lambda_function.integration.arn
}

# Custom EventBridge bus receiving events from Lacework
resource "aws_cloudwatch_event_bus" "lacework" {
  name = local.event_bus_name
  tags = var.tags
}

# Allow the Lacework AWS account to PutEvents on this bus
resource "aws_cloudwatch_event_permission" "lacework" {
  event_bus_name = aws_cloudwatch_event_bus.lacework.name
  principal      = var.lacework_aws_account_id
  statement_id   = "${replace(local.name_prefix, "-", "")}LaceworkAccess"
  action         = "events:PutEvents"
}

# Rule that catches Lacework events and routes them to SQS
resource "aws_cloudwatch_event_rule" "lacework" {
  name           = local.event_rule_name
  description    = "Capture Lacework events and forward them to ${aws_sqs_queue.events.name}"
  event_bus_name = aws_cloudwatch_event_bus.lacework.name
  state          = "ENABLED"
  tags           = var.tags

  event_pattern = jsonencode({
    account = concat([var.lacework_aws_account_id], var.customer_account_ids)
  })
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule           = aws_cloudwatch_event_rule.lacework.name
  event_bus_name = aws_cloudwatch_event_bus.lacework.name
  target_id      = "${local.name_prefix}-sqs-target"
  arn            = aws_sqs_queue.events.arn

  depends_on = [aws_sqs_queue_policy.events]
}

# Lacework alert channel that publishes into the new event bus
resource "lacework_alert_channel_aws_cloudwatch" "this" {
  name             = local.alert_channel_name
  event_bus_arn    = aws_cloudwatch_event_bus.lacework.arn
  group_issues_by  = "Resources"
  enabled          = true
  test_integration = false

  depends_on = [aws_cloudwatch_event_permission.lacework]
}

# Alert rule wiring severities and subcategories to the channel
resource "lacework_alert_rule" "this" {
  name                = local.alert_rule_name
  description         = "Alert rule for the ${local.name_prefix} Security Hub integration"
  alert_channels      = [lacework_alert_channel_aws_cloudwatch.this.id]
  severities          = var.severities
  alert_subcategories = var.alert_subcategories
}
