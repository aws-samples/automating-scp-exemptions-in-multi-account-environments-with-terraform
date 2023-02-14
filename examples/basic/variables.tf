variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
  validation {
    condition     = can(regex("^o-[a-z0-9]{10,32}$", var.organization_id)) && length(var.organization_id) == 12
    error_message = "The Org Id must be a 12 character string starting with o- and followed by 10 lower case alphanumeric characters."
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

variable "scp_home_region" {
  description = "The region from which this module will be executed. This MUST be the same region as the SSM automation."
  type        = string
  validation {
    condition     = can(regex("(us(-gov)?|ap|ca|cn|eu|sa)-(central|(north|south)?(east|west)?)-\\d", var.scp_home_region))
    error_message = "Variable var: region is not valid."
  }
}
