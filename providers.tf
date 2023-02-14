terraform {
  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #   }
  # }

  backend "s3" {
    bucket = "example-terraform-state-bucket"
    key    = "scp-exemption-solution/"
    region = "us-west-2"
  }

}

provider "aws" {
  region  = var.region_primary
  alias   = "scp_exemption_deployment_account"

}

# SCP Exemption Solution - Managed Account 1
provider "aws" {
  region = var.region_primary
  alias   = "scp_exemption_managed_account_1"
  
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
    session_name = "deploy_scp_exemption_role"
    #external_id  = "EXTERNAL_ID"
  }

}

# SCP Exemption Solution - Managed Account 2
provider "aws" {
  region = var.region_primary
  alias   = "scp_exemption_managed_account_2"
  
  assume_role {
    role_arn     = "arn:aws:iam::123456789012:role/ROLE_NAME"
    session_name = "deploy_scp_exemption_role"
    #external_id  = "EXTERNAL_ID"
  }

}