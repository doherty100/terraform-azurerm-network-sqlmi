# Secure Virtual Network for SQL Managed Instance

This configuration provisions a secure "spoke" Azure Virtual Network (VNet) for use with Azure SQL Managed Instance as described in the article:
* [Connectivity architecture for a managed instance in Azure SQL Database](https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture)

This configuration does not provision Azure SQL Managed Instance because it is not currently supported by the Azure provider for Terraform. It does however deploy the necessary infrastructure required to access an Azure SQL Managed Instance from your private on-premise network. After using this template, you must manually install Azure SQL Managed Instance using the Azure Portal or an ARM Template. 

## main.tf
Configures providers and provisions resources. Azure requires that an application is added to Azure Active Directory to generate the `client_id`, `client_secret`, and `tenant_id` needed by Terraform (`subscription_id` can be recovered from your Azure account details). Please go [here](https://www.terraform.io/docs/providers/azurerm/) for full instructions on how to create this to populate your `provider.tf` file. The following resources are provisioned:

* A Resource Group.
* A "spoke" Virtual Network with two subnets. In order to enable connectivity with your on-premises network, the "spoke" VNet must be manually peered with an existing "hub" VNet after it is provisioned. For more information on hybrid connectivity and hub-spoke topologies, see [Choose a solution for connecting an on-premises network to Azure](https://docs.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/). Be sure to configure a unique `address_space` that is contiguous with your other VNets, as well as the correct `dns_server` settings to ensure connectivity with your on-premises network.
* Two subnets, a default subnet and a dedicated subnet for Azure SQL Managed Instance. 
* A Network Security Group used to secure inbound and outbound traffic to the Azure SQL Managed Instance subnet. Note that in the future this can be automatically configured and maintained over time as a managed service via "delegated subnet" functionality pending support by Azure SQL Managed Instance.
* A User Defined Route table used to route traffic between Azure SQL Managed Instance nodes and your private on-premises network. Note that in the future this can be automatically configured and maintained over time as a managed service via "delegated subnet" functionality pending support by Azure SQL Managed Instance.

## terraform.tfvars
Defines the variables used in this template. If a `terraform.tfvars` or any `.auto.tfvars` files are present in the current directory, Terraform automatically loads them to populate variables. We don't recommend saving usernames and password to version control, but you can create a local secret variables file and use the `-var-file` flag or the `.auto.tfvars` extension to load it.

## variables.tf
The `variables.tf` file contains all of the input parameters that the user can specify when deploying this Terraform template. A sample is provided in this template that you can customize for your environment.

![graph](graph.png)
