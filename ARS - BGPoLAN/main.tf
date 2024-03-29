terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=3.11"
    }
    aviatrix = {
      source = "AviatrixSystems/aviatrix"
      version = ">=2.21"
    }
    http-full = {
      source = "Emanuel-Sifuentes/http-full"
      version = ">=0.2"
    }
    time = {
      source = "hashicorp/time"
      version = ">=0.7.2"
    }
    random = {
      source = "hashicorp/random"
      version = ">=3.3.1"
    }
  }
}

provider "azurerm" {
	subscription_id = var.az-sub-id
	client_id = var.az-app-id
	client_secret = var.az-app-secret
	tenant_id = var.az-tenant-id
	features {
    resource_group {
      prevent_deletion_if_contains_resources = false
      }
  }
}

provider "aviatrix" {
  controller_ip = var.controller-fqdn
  password = var.controller-pwd
  username = var.controller-user
  verify_ssl_certificate = false
  skip_version_validation = true
}

provider "http-full" {
}

provider "time" {
}

provider "random" {
}

resource "aviatrix_account" "az_account" {
    account_name = "azure-${random_string.az-avtxlabsa-random.id}"
    cloud_type = 8
    arm_application_id = var.az-app-id
    arm_subscription_id = var.az-sub-id
    arm_application_key = var.az-app-secret
    arm_directory_id = var.az-tenant-id
    
}

/*
This will retrieve public IP of machine running terraform apply command in order to add the IP to the SG ACL
If you execute it remotely (non-local machijne), make sure that you add the IP you wish to use to SSH into VM
*/
data "http" "get_ip" {
    url = "https://api.ipify.org"
}