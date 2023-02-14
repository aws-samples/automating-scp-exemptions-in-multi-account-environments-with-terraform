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

locals {
  ssm_automation_account              = join(":", ["arn", data.aws_partition.current.partition, "iam:", var.ssm_automation_account_id, "root"])
  ssm_automation_role_arn             = join(":", ["arn", data.aws_partition.current.partition, "iam:", var.ssm_automation_account_id, "role/${var.ssm_automation_admin_role_name}"])
  ssm_execution_role_arn              = join(":", ["arn", data.aws_partition.current.partition, "iam:", data.aws_caller_identity.current.account_id, "role/${var.ssm_execution_role_name}"])
  ssm_automation_definition           = join(":", ["arn", data.aws_partition.current.partition, "ssm", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "automation-definition/${var.ssm_document_name_prefix}*"])
  ssm_automation_definition_us_east_1 = join(":", ["arn", data.aws_partition.current.partition, "ssm", "us-east-1", data.aws_caller_identity.current.account_id, "automation-definition/${var.ssm_document_name_prefix}*"])
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_execution_assume_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.ssm_automation_account]
    }
    actions = ["sts:AssumeRole"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = [local.ssm_automation_role_arn]
    }
  }
}

data "aws_iam_policy_document" "ssm_execution_policy_content" {
  statement {
    sid    = "AllowIAM"
    effect = "Allow"
    actions = ["iam:GetRole",
      "iam:GetUser",
      "iam:ListRoles",
      "iam:ListRoleTags",
      "iam:ListUsers",
      "iam:ListUserTags",
      "iam:TagRole",
      "iam:TagUser",
      "iam:UntagRole",
    "iam:UntagUser"]
    resources = ["*"]
  }

  statement {
    sid       = "AllowIAMPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [local.ssm_execution_role_arn]
  }

  statement {
    sid     = "AllowSSMAutomation"
    effect  = "Allow"
    actions = ["ssm:StartAutomationExecution"]
    resources = [local.ssm_automation_definition,
    local.ssm_automation_definition_us_east_1]
  }


}

# Create the policy
resource "aws_iam_policy" "ssm_execution_policy" {
  name        = "SCP_Exemption_SSM_Execution_Policy"
  description = "The SSM automation document uses this policy for tagging/untagging."
  policy      = data.aws_iam_policy_document.ssm_execution_policy_content.json
}

# Creating the role
resource "aws_iam_role" "ssm_execution_role" {
  name               = var.ssm_execution_role_name
  description        = "Creates the role used to execute the SSM automation."
  assume_role_policy = data.aws_iam_policy_document.ssm_execution_assume_policy.json
  path               = "/"
  tags = {
    application-id = var.application_tag_value
  }

}

# Adding the Permissions Policy to the Role
resource "aws_iam_role_policy_attachment" "ssm_execution_role_permissions_policy" {
  role       = aws_iam_role.ssm_execution_role.id
  policy_arn = aws_iam_policy.ssm_execution_policy.arn
}