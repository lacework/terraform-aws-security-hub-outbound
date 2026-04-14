# Configure the Lacework provider.
# See: https://registry.terraform.io/providers/lacework/lacework/latest/docs
provider "lacework" {
  profile = "default"
}

module "security_hub_outbound" {
  source = "../.."

  # Your Lacework account URL, e.g. "account.lacework.net".
  lacework_url = "account.lacework.net"

  # Uncomment to override the default resource name prefix.
  # resource_prefix = "lw-sechub"

  # Uncomment to restrict severities or subcategories forwarded to Security Hub.
  # severities          = ["Critical", "High"]
  # alert_subcategories = ["Compliance", "Cloud Activity"]

  tags = {
    ManagedBy = "terraform"
  }
}
