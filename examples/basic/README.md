# Sample Deployment of SCP Exemption Resources

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.15.0 |
| <a name="requirement_scp_management_account"></a> [scp\_management\_account](#requirement\_scp\_management\_account) | >= 4.9.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_scp-exemption-resources"></a> [scp-exemption-resources](#module\_scp-exemption-resources) | ../../modules/scp-exemption-resources | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_lambda_source_bucket"></a> [lambda\_source\_bucket](#input\_lambda\_source\_bucket) | S3 bucket containing the Lambda Zip file | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | AWS Organizations ID | `string` | n/a | yes |
| <a name="input_scp_home_region"></a> [scp\_home\_region](#input\_scp\_home\_region) | The region from which this module will be executed. This MUST be the same region as the SSM automation. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->