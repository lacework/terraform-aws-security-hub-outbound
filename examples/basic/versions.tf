terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 2.3"
    }
  }
}
