# Overview of Aviatrix Transit with BGP over LAN connection to ARS
This lab will deploy an Aviatrix Transit with a three Aviatrix spokes. Additionally, it will deploy a "legacy" hub-and-spoke architecture, with 2 NVAs, using native Azure constructs. This lab will leverage Azure Route Server in order to connect these two environments together while maintaining traffic symmetry throughout.  

The following variables need to be defined within the variables.tf file

- **controller-fqdn** - Public IP of your Aviatrix Controller
- **controller-user** - Admin account for your Aviatrix Controller
- **controller-pwd** - Admin account for your Aviatrix Controller
- **az-sub-id** - Azure subscription ID to be used for resource deployment
- **az-app-id** - SPN App ID of the Azure App used by Terraform
- **az-app-secret** - Azure secret for the Azure App used by Terraform
- **az-tenant-id** - Azure tenant ID to identify AAD tenant
- **az-region** - Azure region for resources to be deployed in (defaults to East US 2)

Additionally, it is recommended that you change the pre-defined password variables to avoid any security concerns. 

# Post-deployment

Will add later....

# Architecture

![Reference Architecture](https://raw.githubusercontent.com/Emanuel-Sifuentes/AviatrixLabs/main/AKS%20and%20Azure%20Firewall/AKS%20-%20AzFw%20Scenario.png)