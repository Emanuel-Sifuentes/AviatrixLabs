variable "avx_controller_public_ip" {
  type        = string
  description = "aviatrix controller public ip address(required)"
  default = "controller.contoso.com"
}

variable "avx_controller_old_admin_password" {
  type        = string
  sensitive   = true
  description = "aviatrix controller admin password"
  default = "oldPassword12345!"
}

variable "avx_controller_new_admin_password" {
  type        = string
  sensitive   = true
  description = "aviatrix controller admin password"
  default = "newPassword12345!"
}

variable "aviatrix_customer_id" {
  type        = string
  description = "aviatrix customer license id"
  default = "aviatrix.com-abu-xxxxxxxx-xxxxxxxx.xxxx"
}