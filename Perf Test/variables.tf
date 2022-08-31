variable "az-sub-id" {
    type = string
    description = "Azure subscription"
    default = "xxxxx-xxxxx-SubId-xxxxx-xxxxx"
}

variable "az-app-id" {
    type = string
    description = "Azure app ID"
    default = "xxxxx-xxxxx-AppId-xxxxx-xxxxx"
}

variable "az-app-secret" {
    type = string
    description = "Azure secret"
    default = "xxxxx-xxxxx-AppSecret-xxxxx-xxxxx" 
}

variable "az-tenant-id" {
    type = string
    description = "Azure tenant ID"
    default = "xxxxx-xxxxx-TenantId-xxxxx-xxxxx" 
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

variable "az-jumpbox-vm-size" {
    type = string
    description = "Size of Azure VM for test instances"
    default = "Standard_B2ms"
}

variable "az-vm-user" {
    type = string
    description = "Username to access Azure VMs"
    default = "avtxadmin"
}

variable "az-vm-user-pwd" {
    type = string
    description = "Password for Azure VM user"
    default = "P@ssw0rd123456!"
}

variable "controller-fqdn" {
    type = string
    description = "Public IP of Aviatrix Controller"
    default = "controller.contoso.com"
}

variable "controller-user" {
    type = string
    description = "Admin username for Aviatrix controller"
    default = "admin"
}

variable "controller-pwd" {
    type = string 
    description = "Admin password for Aviatrix controller"
    default = "P@ssw0rd123456!"
}

variable "az-spoke-list" {
    type = list
    description = "Array containing information about AZ VPCs to be created"
    default = [
        {
            "vnet_name": "az-eu2-spoke1-vnet",
            "firenet_enabled": false,
            "cidr": "10.1.10.0/23"
        },
        {
            "vnet_name": "az-eu2-spoke2-vnet",
            "firenet_enabled": false,
            "cidr": "10.1.20.0/23"
        },
        {
            "vnet_name": "az-eu2-jumpbox-vnet",
            "firenet_enabled": false,
            "cidr": "10.0.0.0/23"
        },
        {
            "vnet_name": "az-eu2-spoke3-vnet",
            "firenet_enabled": false,
            "cidr": "10.2.10.0/23"
        },
        {
            "vnet_name": "az-eu2-spoke4-vnet",
            "firenet_enabled": false,
            "cidr": "10.2.20.0/23"
        }
    ]
}

variable "az-transit-list" {
    type = list
    description = "Array containing information about AZ VPCs to be created"
    default = [
        {
            "vnet_name": "az-eu2-firenet1-vnet",
            "firenet_enabled": true,
            "cidr": "10.1.0.0/23"
        },
        {
            "vnet_name": "az-eu2-firenet2-vnet",
            "firenet_enabled": true,
            "cidr": "10.2.0.0/23"
        }
    ]
}

variable "az-transit-gw-size" {
    type = string
    description = "Size for Azure transit gateways"
    default = "Standard_F32s_v2"
}

variable "az-spoke-gw-size" {
    type = string
    description = "Size for Azure spoke gateways"
    default = "Standard_D8_v3"
}

variable "az-vm-size" {
    type = string
    description = "Size for Azure VMs"
    default = "Standard_D8_v4"
}