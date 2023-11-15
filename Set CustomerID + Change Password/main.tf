terraform {
  required_providers {
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  #powershell = option = format("%s\\update_customerId.py", path.root)
  option = format("%s/update_customerId.py", path.root)
  argument = format("'%s' '%s' '%s' '%s'",
    var.avx_controller_public_ip, var.avx_controller_old_admin_password, var.avx_controller_new_admin_password, var.aviatrix_customer_id
  )
}

resource "null_resource" "run_script" {
  provisioner "local-exec" {
    #interpreter = ["PowerShell", "-Command"]
    command = "python3 -W ignore ${local.option} ${local.argument}"
  }
}