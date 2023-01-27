variable "az-sub-id" {
    type = string
    description = "Azure subscription"
    default = "xxxxxxx-xxxxxxx-xxxxxxx-xxxxxxx"
}

variable "az-app-id" {
    type = string
    description = "Azure app ID"
    default = "xxxxxxx-xxxxxxx-xxxxxxx-xxxxxxx"
}

variable "az-app-secret" {
    type = string
    description = "Azure secret"
    default = "az-app-secret" 
}

variable "az-tenant-id" {
    type = string
    description = "Azure tenant ID"
    default = "xxxxxxx-xxxxxxx-xxxxxxx-xxxxxxx" 
}

variable "az-region" {
    type = string
    description = "Azure region for resources"
    default = "East US 2"
}

variable "az-rg-name" {
    type = string
    description = "Resource group name where Azure resources will be deployed"
    default = "az-avtx-rg"
}

variable "az-vm-size" {
    type = string
    description = "Size of Azure VM for test instances"
    default = "Standard_D2_v3"
}

variable "az-jumpbox-vm-size" {
    type = string
    description = "Size of Azure VM for test instances"
    default = "Standard_B2ms"
}

variable "az-vm-user" {
    type = string
    description = "Username to access Azure VMs"
    default = "avtxlabuser"
}

variable "az-vm-user-pwd" {
    type = string
    description = "Password for Azure VM user"
    default = "AvtxLabPass123!"
}

variable "controller-fqdn" {
    type = string
    description = "Public IP or FQDN of Aviatrix Controller"
    default = "controller.avtxdemo.com"
}

variable "controller-user" {
    type = string
    description = "Admin username for Aviatrix controller"
    default = "admin"
}

variable "controller-pwd" {
    type = string 
    description = "Admin password for Aviatrix controller"
    default = "AvtxLabPass123!"
}

variable "az-vpc-list" {
    type = list
    description = "Array containing information about AZ VPCs to be created"
    default = [
        {
            "vpc_name": "az-eu2-spoke1-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "2"
        },
        {
            "vpc_name": "az-eu2-spoke2-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "4"
        },
        {
            "vpc_name": "az-eu2-jumpbox-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "8"
        },
        {
            "vpc_name": "az-eu2-firenet-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "10"
        }
    ]
}

variable "az-spoke-list" {
    type = list
    description = "Array containing information about AZ VPCs to be created"
    default = [
        {
            "vpc_name": "az-eu2-spoke1-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "2"
        },
        {
            "vpc_name": "az-eu2-spoke2-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "4"
        }
    ]
}

variable "az-transit-gw-size" {
    type = string
    description = "Size for Azure gateways"
    default = "Standard_D8s_v3"
}

variable "az-spoke-gw-size" {
    type = string
    description = "Size for Azure gateways"
    default = "Standard_D2s_v3"
}

variable "az-ars-vnet" {
    type = map
    description = "Values fo the ARS VNET"
    default = {
        "name" : "az-ars-vnet",
        "cidr" : "10.50.0.0/24",
        "gw_snet_cidr" : "10.50.0.64/26",
        "nva_snet_cidr" : "10.50.0.0/26"
    }
}

variable "az-ars-spoke1-vnet" {
    type = map
    description = "Values fo the ARS spoke1 VNET"
    default = {
        "name" : "az-ars-spoke1-vnet",
        "cidr" : "10.50.1.0/24",
        "vm_snet_cidr" : "10.50.1.0/26"
    }
}

variable "az-ars-nva-asn" {
    type = string
    description = "ASN for the NVAs to be deployed in the ARS VNET"
    default = "65521"
}

variable "az-ars-nva-ilb-ip" {
    type = string
    description = "Static IP for the NVA ILB"
    default = "10.50.0.10"
}