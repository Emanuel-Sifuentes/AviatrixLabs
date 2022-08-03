variable "az-sub-id" {
    type = string
    description = "Azure subscription to be used for deployment"
    default = "xxxxx-xxxxx-subId-xxxx-xxxxxxxxx"
}

variable "az-app-id" {
    type = string
    description = "App ID of the Azure App used by Terraform"
    default = "xxxxx-xxxxx-appId-xxxx-xxxxxxxxx"
}

variable "az-app-secret" {
    type = string
    description = "Azure secret for the Azure App used by Terraform"
    default = "xxxxx-xxxxx-appSecret-xxxx-xxxxxxxxx"
}

variable "az-tenant-id" {
    type = string
    description = "Azure tenant ID to identify AAD tenant"
    default = "xxxxx-xxxxx-tenantId-xxxx-xxxxxxxxx"
}

variable "az-region" {
    type = string
    description = "Azure region for resources to be deployed in"
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
    default = "P@ssw0rd12345!"
}

variable "controller-public-ip" {
    type = string
    description = "Public IP of Aviatrix Controller"
    default = "1.1.1.1"
}

variable "controller-user" {
    type = string
    description = "Admin username for Aviatrix controller"
    default = "avtxadmin"
}

variable "controller-pwd" {
    type = string 
    description = "Admin password for Aviatrix controller"
    default = "P@ssword12345!"
}

variable "az-vpc-list" {
    type = list
    description = "Array containing information about AZ VPCs to be created"
    default = [
        {
            "vpc_name": "az-spoke1-vnet",
            "account_type": "8",
            "firenet_enabled": false,
            "octet": "0"
        },
        {
            "vpc_name": "az-transit-firenet-vnet",
            "account_type": "8",
            "firenet_enabled": true,
            "octet": "10"
        },
    ]
}

variable "az-ssh-key-value" {
    type = string
    description = "Value of SSH public key"
    default = "ssh-rsa A123public1ssh2key3value"
}

variable "az-gw-size" {
    type = string
    description = "Size for Azure gateways"
    default = "Standard_B2ms"
}


variable "aks-rg-name" {
    type = string
    description = "Name of the AKS resource group name"
    default = "az-aks-rg"
}

variable "aks-vnet-name" {
    type = string
    description = "Name of the AKS VNET"
    default = "az-aks-vnet"
}

variable "aks-name" {
    type = string
    description = "Name of the AKS cluster"
    default = "az-aks-cluster"
}

variable "aks-dns-prefix" {
    type = string
    description = "DNS prefix of the AKS cluster"
    default = "az-aks"
}

variable "aks-vnet-cidr" {
    type = string
    description = "CIDR range for the on-premise network (Minimum /26)"
    default = "10.100.0.0/22"
}

variable "sql-name" {
    type = string
    description = "Name of the Azure SQL Server"
    default = "az-sql"
}

variable "sql-user" {
    type = string
    description = "Admin username for the Azure SQL Server"
    default = "avtxadmin"
}

variable "sql-pwd" {
    type = string
    description = "Admin password for the Azure SQL Server"
    default = "P@ssw0rd12345!"
}