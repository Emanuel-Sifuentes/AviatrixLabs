variable "avx_controller_public_ip" {
  type        = string
  description = "aviatrix controller public ip address(required)"
  default = "controller.contoso.com"
}

variable "avx_controller_admin_password" {
  type        = string
  sensitive   = true
  description = "aviatrix controller admin password"
  default = "superSecretPassword"
}

variable "aviatrix_customer_id" {
  type        = string
  description = "aviatrix customer license id"
  default = "contoso.com-abu-xxxxxxxxx-1234567890.12"
}