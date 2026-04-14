# Integrate AWS Security Hub with Lacework (Outbound)

The following example forwards Lacework alerts to AWS Security Hub via an EventBridge bus, SQS queue, and Lambda transformer deployed in a single AWS region.

## Sample Code

```hcl
provider "aws" {}

provider "lacework" {}

module "security_hub_outbound" {
  source  = "lacework/security-hub-outbound/aws"
  version = "~> 0.1"

  # Your Lacework account URL, e.g. "account.lacework.net".
  lacework_url = "account.lacework.net"
}
```

Optionally, filter the Lacework alerts that reach Security Hub by severity or subcategory:

```hcl
module "security_hub_outbound" {
  source  = "lacework/security-hub-outbound/aws"
  version = "~> 0.1"

  lacework_url = "account.lacework.net"

  severities          = ["Critical", "High"]
  alert_subcategories = ["Compliance", "Cloud Activity"]
}
```

A `tags` block can be used to add custom tags to the resources managed by the module:

```hcl
module "security_hub_outbound" {
  source  = "lacework/security-hub-outbound/aws"
  version = "~> 0.1"

  lacework_url = "account.lacework.net"

  tags = {
    ManagedBy = "terraform"
  }
}
```
