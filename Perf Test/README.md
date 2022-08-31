# Overview of Aviatrix Functional Testing Lab 
This lab shows how to deploy an Aviatrix multi-hub-and-spoke topology in Azure to be used as a testbed for functional testing or as a sandbox environment.   

The following variables need to be defined within the variables.tf file

- **controller-public-ip** - Public IP of your Aviatrix Controller
- **controller-user** - Admin account for your Aviatrix Controller
- **controller-pwd** - Admin account for your Aviatrix Controller
- **az-sub-id** - Azure subscription ID to be used for resource deployment
- **az-app-id** - SPN App ID of the Azure App used by Terraform (Note: To create an SPN with the minimum required permissions, use this [GitHub repository](https://github.com/AviatrixSystems/terraform-aviatrix-azure-controller/tree/master/modules/aviatrix_controller_azure))
- **az-app-secret** - Azure secret for the Azure App used by Terraform
- **az-tenant-id** - Azure tenant ID to identify AAD tenant
- **az-region** - Azure region for resources to be deployed in (defaults to East US 2)
- **az-transit-gw-size** - VM size of the Aviatrix Transit Gateways (defaults to Standard_F32s_v2)
- **az-spoke-gw-size** - VM size of the Aviatrix Spoke Gateways (defaults to Standard_D8_v3)
- **az-vm-size** - VM size of the Spoke VMs (defaults to Standard_D8_v4)

Additionally, it is recommended that you change the pre-defined password variables to avoid any security concerns. 

# Architecture

![Reference Architecture](https://raw.githubusercontent.com/Emanuel-Sifuentes/AviatrixLabs/main/Perf%20Test/Virtual%20Functional%20Testing.png)