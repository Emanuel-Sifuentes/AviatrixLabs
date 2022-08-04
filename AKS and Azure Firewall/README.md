# Overview of AKS and Azure Firewall Lab with Aviatrix 
This lab shows how to deploy an AKS cluster, using Azure CNI, and using an Aviatrix FQDN Egress gateway for localized egressn and using AGIC for ingress. Additionally, we will be using Azure Firewall (FWaaS) and integrating it onto  Aviatrix Firenet. 

The following variables need to be defined within the variables.tf file

- **controller-public-ip** - Public IP of your Aviatrix Controller
- **controller-user** - Admin account for your Aviatrix Controller
- **controller-pwd** - Admin account for your Aviatrix Controller
- **az-sub-id** - Azure subscription ID to be used for resource deployment
- **az-app-id** - SPN App ID of the Azure App used by Terraform
- **az-app-secret** - Azure secret for the Azure App used by Terraform
- **az-tenant-id** - Azure tenant ID to identify AAD tenant
- **az-region** - Azure region for resources to be deployed in (defaults to East US 2)

Additionally, it is recommended that you change the pre-defined password variables to avoid any security concerns. 

# Post-deployment

Once the deployment has finished, there a couple of things that must be done in order to ensure the environment is set up correctly. 

1. Run the **routeTransfer.ps1** script - this can be done from your local machine if you have AZ PowerShell installed, or you can run it from [shell.azure.com](https://shell.azure.com). Make sure to clone the script and edit the subscription ID to point to the correct subscription. 

2. Edit the **deployment.yaml** file to point the environment variable, *SQL_SERVER_FQDN*, to the right AzSQL FQDN (i.e. az-sql-2jd44n.database.windows.net) that is part of your output list.

3. Deploy the troubleshooting app to the AKS cluster. You will need [kubectl](https://kubernetes.io/docs/tasks/tools/) installed to do so. 
    ```bash
    cd '~/AKS and Azure Firewall/' 
    mv ./kubeconfig ~/.kube/config
    kubectl get node
    kubectl create -f deployment.yaml
    #Wait a couple of minutes
    kubectl get ingress
    ```

# Architecture (Coming Soon)