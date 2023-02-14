variable "region_primary" {
  description = "Region to deploy"
  default     = "us-west-2"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z]{2}-\\w+-[0-9]{1,2}$", var.region_primary))
    error_message = "The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, '_', '.', '/', '=', '+', '-'."
  }
}

variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id)) && length(var.organization_id) == 12
    error_message = "The Org Id must be a 12 character string starting with o- and followed by 10 lower case alphanumeric characters."
  }
}

variable "log_level" {
  description = "Lambda Function Logging Level"
  default     = "debug"
  type        = string
  validation {
    condition     = can(regex("^(debug||info||warning||error||critical){1}$", var.log_level))
    error_message = "Allowed values are: [debug, info, warning, error, critical]."
  }
}

variable "application_tag_value" {
  description = "Application tag key value"
  default     = "scp-exemption"
  type        = string
  validation {
    condition     = can(regex("^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*)$", var.application_tag_value))
    error_message = "The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, '_', '.', '/', '=', '+', '-'."
  }
}


# DynamoDB Variables ----------------------------------
variable "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  default     = "scp-exemption"
  type        = string
  validation {
    condition     = can(regex("[a-zA-Z0-9_.-]+", var.dynamodb_table_name))
    error_message = "Between 3 and 255 characters long. (A-Z,a-z,0-9,_,-,.)."
  }
}

# SSM Variables ----------------------------------
variable "ssm_automation_admin_role_name" {
  description = "SSM Automation Admin Role Name"
  default     = "scp-exemption-ssm-automation-admin"
  type        = string
  validation {
    condition     = can(regex("^[\\w+=,.@-]{1,64}$", var.ssm_automation_admin_role_name))
    error_message = "Max 64 alphanumeric characters. Also special characters supported [+, =, ., @, -]."
  }
}

variable "ssm_execution_role_name" {
  description = "SSM automation execution role name"
  default     = "scp-exemption-ssm-automation-execution"
  type        = string
  validation {
    condition     = can(regex("^[\\w+=,.@-]{1,64}$", var.ssm_execution_role_name))
    error_message = "Max 64 alphanumeric characters. Also special characters supported [+, =, ., @, -]."
  }
}

variable "scp_exemption_ssm_document_name" {
  description = "Tagging SSM Document Name"
  type        = string
  default     = "scp-exemption-tag"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-.]{3,128}$", var.scp_exemption_ssm_document_name))
    error_message = "Between 3 and 128 characters and cannot be prefixed with \"aws-, amazon, amzn\"."
  }
}

variable "cleanup_ssm_document_name" {
  description = "Cleanup SSM Document Name"
  default     = "scp-exemption-cleanup"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_\\-.]{3,128}$", var.cleanup_ssm_document_name))
    error_message = "Between 3 and 128 characters and cannot be prefixed with \"aws-, amazon, amzn\"."
  }
}

# Lambda Variables ----------------------------------
variable "lambda_function_name" {
  description = "DynamoDB stream Lambda function name"
  default     = "scp-exemption-lambda"
  type        = string
  validation {
    condition     = can(regex("^[\\w-]{0,64}$", var.lambda_function_name))
    error_message = "Max 64 alphanumeric characters. Also special characters supported [_, -]."
  }
}

variable "lambda_log_group_retention" {
  description = " Specifies the number of days you want to retain Lambda log events in the CloudWatch Logs"
  default     = "14"
  type        = string
  validation {
    condition     = can(regex("^(1||3||5||7||14||30||60||90||120||150||180||365||400||545||731||1827||3653){1}$", var.lambda_log_group_retention))
    error_message = "Allowed values are: [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653]."
  }
}

variable "lambda_role_name" {
  description = "Lambda Role Name"
  default     = "scp-exemption-lambda-role"
  type        = string
  validation {
    condition     = can(regex("^[\\w+=,.@-]{1,64}$", var.lambda_role_name))
    error_message = "Max 64 alphanumeric characters. Also special characters supported [+, =, ., @, -]."
  }
}

variable "lambda_source_bucket" {
  description = "S3 bucket containing the Lambda Zip file"
  type        = string
  validation {
    condition     = can(regex("^$|^[0-9a-zA-Z]+([0-9a-zA-Z-]*[0-9a-zA-Z])*$", var.lambda_source_bucket))
    error_message = "S3 bucket name can include numbers, lowercase letters, uppercase letters, and hyphens (-). It cannot start or end with a hyphen (-)."
  }
}

variable "lambda_zip_file_name" {
  description = "Lambda zip file containing code"
  default     = "scp-exemption-db-stream-lambda.zip"
  type        = string
}
