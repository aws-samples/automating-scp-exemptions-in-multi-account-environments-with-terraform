terraform {
  required_version = ">= 0.15.0"
  required_providers {
    scp_management_account = {
      source  = "hashicorp/aws"
      version = ">= 4.9.0"
    }
  }
}

provider "aws" {
  # The default profile or environment variables should authenticate to the security/management account as Administrator
  region = var.scp_home_region
  alias  = "scp_management_account"
}
