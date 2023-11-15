# Aviatrix Controller - Update customerID

This terraform module updates the customer ID, used for licensing, on the Aviatrix Controller. The following actions are performed:
1. Wait until API server of Aviatrix Controller is up and running
2. Login Aviatrix Controller and get CID
3. Set Aviatrix Customer ID


## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [null_resource.run_script](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_avx_controller_public_ip"></a> [avx\_controller\_public\_ip](#input\_avx\_controller\_public\_ip) | aviatrix controller public ip address(required) | `string` | n/a | yes |
| <a name="input_avx_controller_admin_password"></a> [avx\_controller\old\_admin\_password](#input\_avx\_controller\_old\_admin\_password) | aviatrix controller old admin password | `string` | n/a | yes |
| <a name="input_avx_controller_admin_password"></a> [avx\_controller\new\_admin\_password](#input\_avx\_controller\_new\_admin\_password) | aviatrix controller new admin password | `string` | n/a | yes |
| <a name="input_aviatrix_customer_id"></a> [aviatrix\_customer\_id](#input\_aviatrix\_customer\_id) | aviatrix customer license id | `string` | n/a | yes |

## Outputs

No outputs.

## APIs Used

* `login`
* `setup_customer_id`
* `edit_account_user`