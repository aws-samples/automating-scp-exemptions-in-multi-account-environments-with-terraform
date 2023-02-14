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

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  ssm_role_arn   = join(":", ["arn", data.aws_partition.current.partition, "iam::*", "role/${var.ssm_execution_role_name}"])
  dynamodb_table = join(":", ["arn", data.aws_partition.current.partition, "dynamodb", data.aws_region.current.name, data.aws_caller_identity.current.account_id, "table/${aws_dynamodb_table.scp_exemption_dynamodb.name}"])
  log_group_log_stream = join(":", [aws_cloudwatch_log_group.lambda_function_log_group.arn, "log-stream", "*"])
  ssm_automation_definition_tag_doc = join(":",["arn:aws:ssm:*",data.aws_caller_identity.current.account_id,"automation-definition/${var.scp_exemption_ssm_document_name}*"])
  ssm_automation_definition_untag_doc = join(":",["arn:aws:ssm:*",data.aws_caller_identity.current.account_id,"automation-definition/${var.cleanup_ssm_document_name}*"])
}

data "aws_iam_policy_document" "ssm_automation_admin_assume_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

}

data "aws_iam_policy_document" "ssm_automation_admin_policy_content" {
  statement {
    sid       = "AssumeRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [local.ssm_role_arn]
    #condition {
    #    test = "StringEquals"
    #    variable = " aws:PrincipalOrgId"
    #    values = [var.organization_id]
    #}
  }
  statement {
    sid       = "Organizations"
    effect    = "Allow"
    actions   = ["organizations:ListAccountsForParent", "organizations:ListAccounts"]
    resources = ["*"]
  }

  statement {
    sid       = "DynamoDBTable"
    effect    = "Allow"
    actions   = ["dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.scp_exemption_dynamodb.arn]
  }

}

data "aws_iam_policy_document" "scp_exemption_lambda_role_trust_relationships" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

}

data "aws_iam_policy_document" "scp_exemption_lambda_function_permission_policy" {
  statement {
    sid       = "CreateLogGroup"
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = [aws_cloudwatch_log_group.lambda_function_log_group.arn]
  }
  statement {
    sid    = "CreateLogStreamAndEvents"
    effect = "Allow"
    actions = ["logs:CreateLogStream",
               "logs:PutLogEvents"]
    resources = [local.log_group_log_stream]
  }
  statement {
    sid    = "DynamoDBStream"
    effect = "Allow"
    actions = ["dynamodb:DescribeStream",
               "dynamodb:GetRecords",
               "dynamodb:GetShardIterator",
               "dynamodb:ListStreams"]
    resources = [aws_dynamodb_table.scp_exemption_dynamodb.stream_arn]
  }
  statement {
    sid       = "DynamoDBTable"
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.scp_exemption_dynamodb.arn]
  }
  statement {
    sid       = "SSM"
    effect    = "Allow"
    actions   = ["ssm:StartAutomationExecution"]
    resources = [local.ssm_automation_definition_tag_doc,
                 local.ssm_automation_definition_untag_doc]
  }
  statement {
    sid       = "IAM"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.ssm_automation_admin_role.arn]
  }
}



resource "aws_dynamodb_table" "scp_exemption_dynamodb" {
  name         = var.dynamodb_table_name
  billing_mode = "PROVISIONED"

  hash_key  = "pk"
  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }
  attribute {
    name = "sk"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  read_capacity    = 5
  write_capacity   = 5
  stream_view_type = "NEW_AND_OLD_IMAGES"
  stream_enabled   = true
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    application-id = var.application_tag_value
  }

}

# SSM AUTOMATION ADMIN ROLE 

# Creating the role
resource "aws_iam_role" "ssm_automation_admin_role" {
  name               = var.ssm_automation_admin_role_name
  description        = "Creates the role used by SSM automation."
  assume_role_policy = data.aws_iam_policy_document.ssm_automation_admin_assume_policy.json
  path               = "/"
  tags = {
    application-id = var.application_tag_value
  }

}

# Creating the policy
resource "aws_iam_policy" "ssm_automation_admin_policy" {
  name        = "SSM-Automation-Admin-Policy"
  description = "Policy granting SSM automation permissions for tagging"
  policy      = data.aws_iam_policy_document.ssm_automation_admin_policy_content.json
}


# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ssm_automation_admin_role_policy_attachment" {
  role       = aws_iam_role.ssm_automation_admin_role.name
  policy_arn = aws_iam_policy.ssm_automation_admin_policy.arn
}


resource "aws_ssm_document" "ssm_tag_document" {
  name            = var.scp_exemption_ssm_document_name
  document_type   = "Automation"
  document_format = "YAML"

  tags = {
    application-id = var.application_tag_value
  }
  content = templatefile("${path.module}/ssm-automation-documents/scp-exemption-tag.json",
    {
      ssm_automation_admin_assume_role_arn = aws_iam_role.ssm_automation_admin_role.arn
  })

}

resource "aws_ssm_document" "ssm_tag_cleanup_document" {

  name            = var.cleanup_ssm_document_name
  document_type   = "Automation"
  document_format = "YAML"

  tags = {
    application-id = var.application_tag_value
  }

  content = templatefile("${path.module}/ssm-automation-documents/scp-exemption-cleanup.json",
    {
      ssm_automation_admin_assume_role_arn = aws_iam_role.ssm_automation_admin_role.arn
  })
}

resource "aws_cloudwatch_log_group" "lambda_function_log_group" {
  retention_in_days = var.lambda_log_group_retention
  name              = "/aws/lambda/${var.lambda_function_name}"
  #kms_key_id="arn_of_kms_key_used_to_encrypt_here"
}

# LAMBDA ROLE

# Creating the role
resource "aws_iam_role" "scp_exemption_lambda_role" {
  name               = var.lambda_role_name
  description        = "Creates the role used by the Lambda function."
  assume_role_policy = data.aws_iam_policy_document.scp_exemption_lambda_role_trust_relationships.json
  path               = "/"
  tags = {
    application-id = var.application_tag_value
  }
}

# Create the policy
resource "aws_iam_policy" "scp_lambda_function_policy" {
  name        = "SSM-Exemption-Lambda-Function-Policy"
  description = "Policy granting SCP Exemption Lambda Function permissions."
  policy      = data.aws_iam_policy_document.scp_exemption_lambda_function_permission_policy.json
}


# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "scp_exemption_lambda_function_policy_attachment" {
  role       = aws_iam_role.scp_exemption_lambda_role.name
  policy_arn = aws_iam_policy.scp_lambda_function_policy.arn
}



resource "aws_lambda_function" "scp_exemption_lambda_function" {
  description = "Process DynamoDB streams"
  #filename      = "scp-exemption-db-stream-lambda.zip"
  s3_bucket     = var.lambda_source_bucket
  s3_key        = var.lambda_zip_file_name
  function_name = var.lambda_function_name
  role          = aws_iam_role.scp_exemption_lambda_role.arn
  handler       = "app.lambda_handler"
  runtime       = "python3.8"
  memory_size   = 128
  timeout       = 300
  reserved_concurrent_executions = 50
  # (Optional) Amazon Resource Name (ARN) of the AWS Key Management Service (KMS) key that is used to encrypt environment variables. 
  # If this configuration is not provided when environment variables are in use, AWS Lambda uses a default service key. 
  # kms_key_arn = "OPTIONAL: arn_of_kms_key_to_encrypt_environment_variables"
  environment {
    variables = {
      AUTOMATION_ASSUME_ROLE      = aws_iam_role.ssm_automation_admin_role.arn
      CLEANUP_DOCUMENT_NAME       = var.cleanup_ssm_document_name
      EXECUTION_ROLE_NAME         = var.ssm_execution_role_name
      LOG_LEVEL                   = var.log_level
      SCP_EXEMPTION_DOCUMENT_NAME = var.scp_exemption_ssm_document_name
    }
  }

  tags = {
    application-id = var.application_tag_value
  }
}

resource "aws_lambda_event_source_mapping" "scp_exemption_lambda_event_source_mapping" {
  batch_size                     = 100
  bisect_batch_on_function_error = true
  event_source_arn               = aws_dynamodb_table.scp_exemption_dynamodb.stream_arn
  function_name                  = aws_lambda_function.scp_exemption_lambda_function.arn
  maximum_record_age_in_seconds  = 60
  maximum_retry_attempts         = 2
  starting_position              = "LATEST"
}

resource "aws_lambda_permission" "scp_exemption_lambda_permissions" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scp_exemption_lambda_function.arn
  principal     = "dynamodb.amazonaws.com"
  source_arn    = aws_dynamodb_table.scp_exemption_dynamodb.stream_arn

}


output "scp_exemption_dynamodb_table_stream_arn" {
  value = aws_dynamodb_table.scp_exemption_dynamodb.stream_arn
}

output "scp_exemption_ssm_automation_role_arn" {
  value = aws_iam_role.ssm_automation_admin_role.arn
}