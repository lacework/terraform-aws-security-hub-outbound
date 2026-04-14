<!-- BEGIN_TF_DOCS -->
# Terraform AWS Security Hub Outbound Module

Terraform module that integrates the Lacework FortiCNAPP platform with AWS Security Hub.
Lacework events flow into a dedicated EventBridge bus, an SQS queue buffers them, and a
Lambda function transforms each event into an AWS Security Finding Format (ASFF) record
and publishes it to Security Hub via `BatchImportFindings`.

This module creates:
- A dedicated EventBridge bus, rule, and bus policy granting the Lacework AWS account `events:PutEvents`
- An SQS queue (and access policy) that buffers events and triggers the Lambda
- A Go Lambda (`provided.al2023`) that transforms events and calls `securityhub:BatchImportFindings`
- IAM role and policies for the Lambda (SQS read + Security Hub import)
- A Lacework CloudWatch alert channel and alert rule that send events to the new bus

## Usage Examples
See the [examples/](./examples/) directory for complete usage examples.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | ~> 6.0 |
| lacework | ~> 2.3 |

## Providers

| Name | Version |
|------|---------|
| aws | 6.40.0 |
| lacework | 2.3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| alert\_channel\_name | Name for the Lacework CloudWatch alert channel. Defaults to "<resource\_prefix>-channel" when empty. | `string` | `""` | no |
| alert\_rule\_name | Name for the Lacework alert rule. Defaults to "<resource\_prefix>-rule" when empty. | `string` | `""` | no |
| alert\_subcategories | Lacework alert subcategories attached to the alert rule. | `list(string)` | <pre>[<br>  "Compliance",<br>  "Application",<br>  "Cloud Activity",<br>  "File",<br>  "Machine",<br>  "User",<br>  "Platform",<br>  "Kubernetes Activity",<br>  "Registry",<br>  "SystemCall",<br>  "Host Vulnerability",<br>  "Container Vulnerability",<br>  "Threat Intel"<br>]</pre> | no |
| customer\_account\_ids | List of customer AWS account IDs that are configured in Lacework. Joined with var.lacework\_aws\_account\_id to form the EventBridge rule's account filter, so events published from any of these accounts (e.g. "aws events put-events" for smoke tests) are forwarded to the Lambda in addition to those from Lacework's own account. | `list(string)` | `[]` | no |
| default\_aws\_account\_id | AWS account ID that the Lambda maps unknown-source findings to. Defaults to the caller identity when empty. | `string` | `""` | no |
| lacework\_aws\_account\_id | AWS account ID of the Lacework platform. Granted events:PutEvents on the custom EventBridge bus and used as the event\_pattern account filter. | `string` | `"434813966438"` | no |
| lacework\_url | Lacework account URL, e.g. "account.lacework.net" or "org.sub.lacework.net" for Lacework Organizations. Passed to the Lambda as the LACEWORK\_INSTANCE environment variable. | `string` | n/a | yes |
| lambda\_memory\_size | Memory (MB) allocated to the Lambda function. | `number` | `256` | no |
| lambda\_source\_s3\_bucket | Source S3 bucket holding the published Lambda deployment zip. The module copies the object into a stack-local bucket in the consumer's region at apply time, because aws\_lambda\_function requires the code-source bucket to be in the same region as the function. | `string` | `"cloud-automation-templates-prod"` | no |
| lambda\_source\_s3\_key | Source S3 object key for the Lambda deployment zip. Pin to a versioned key (e.g. "aws/lacework-aws-security-hub-outbound/0.1.0/lambda/events\_processor.zip") to control updates; the "latest" key does not trigger redeploys automatically because aws\_s3\_object\_copy is idempotent on the destination key. | `string` | `"aws/lacework-aws-security-hub-outbound/latest/lambda/events_processor.zip"` | no |
| lambda\_timeout | Timeout (seconds) for the Lambda function. | `number` | `30` | no |
| resource\_prefix | Prefix for all created AWS and Lacework resource names. | `string` | `"lw-sechub"` | no |
| severities | Lacework alert severities to forward to Security Hub. | `list(string)` | <pre>[<br>  "Critical",<br>  "High",<br>  "Medium",<br>  "Low",<br>  "Info"<br>]</pre> | no |
| sqs\_message\_retention\_seconds | Message retention period (seconds) on the SQS queue that buffers events for the Lambda. | `number` | `86400` | no |
| tags | Tags applied to all taggable resources. | `map(string)` | <pre>{<br>  "ManagedBy": "terraform"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| event\_bus\_arn | ARN of the custom EventBridge bus that receives Lacework events. |
| event\_bus\_name | Name of the custom EventBridge bus. |
| event\_rule\_arn | ARN of the EventBridge rule that forwards Lacework events to SQS. |
| lacework\_alert\_channel\_id | ID of the Lacework CloudWatch alert channel created by the module. |
| lacework\_alert\_rule\_id | ID of the Lacework alert rule created by the module. |
| lambda\_function\_arn | ARN of the Lambda function that transforms events and publishes to Security Hub. |
| lambda\_function\_name | Name of the Lambda function. |
| lambda\_role\_arn | ARN of the IAM role the Lambda assumes. |
| sqs\_queue\_arn | ARN of the SQS queue buffering events for the Lambda. |
| sqs\_queue\_url | URL of the SQS queue buffering events for the Lambda. |
<!-- END_TF_DOCS -->