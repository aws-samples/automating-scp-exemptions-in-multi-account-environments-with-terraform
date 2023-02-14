#
# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify,
# merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
# PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

## Call Module to Deploy the Prowler ECS Instance and Role
module "ssm_automation_infrastructure" {
  source = "./modules/scp-exemption-resources"
  providers = {
    aws = aws.scp_exemption_deployment_account
  }
  
  # The region where to deploy the SCP Exemption Solution
  region_primary = "us-west-2"
  
  # Your Organization ID
  organization_id = "The id of your organization"
  
  # S3 Bucket Containing the Lambda Function Files
  lambda_source_bucket = "my-example-s3-bucket"

}


#Call Module to Deploy the SCP Exemtion Cross-Account Role
module "scp_exemption_cross_account_role_deploy_1" {
  source = "./modules/scp-exemption-role"
  providers = {
    aws = aws.scp_exemption_managed_account_1
  }
  
  # The AWS account id for the account that will contain the SCP Exemption Solution.
  ssm_automation_account_id = "111111111111"

}

#Call Module to Deploy the SCP Exemtion Cross-Account Role
module "scp_exemption_cross_account_role_deploy_2" {
  source = "./modules/scp-exemption-role"
  providers = {
    aws = aws.scp_exemption_managed_account_2
  }
  
  # The AWS account id for the account that will contain the SCP Exemption Solution.
  ssm_automation_account_id = "111111111111"

}