variable "application_tag_value" {
  description = "Application tag key value"
  default     = "scp-exemption"
  type        = string
  validation {
    condition     = can(regex("^([\\p{L}\\p{Z}\\p{N}_.:/=+\\-@]*)$", var.application_tag_value))
    error_message = "The string value can be Unicode characters. The string can contain only the set of Unicode letters, digits, white-space, '_', '.', '/', '=', '+', '-'."
  }
}

variable "ssm_automation_account_id" {
  description = "SSM Automation Account ID"
  type        = string
}

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

variable "ssm_document_name_prefix" {
  description = "SSM Document Name Prefix"
  default     = "scp-exemption"
  type        = string
}
