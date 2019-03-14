# Modify this file to customize the HDInsight Virtual Network configuration for your specific environment

# General 
resource_prefix = "sqldbmi-dev" # Change this to a prefix that complies with your resource naming conventions

location = "West US 2" # Change this to the region you want to deploy 

tags = {
  environment = "Dev"
  costcenter  = "Unknown"
  project     = "Azure SQL Database Managed Instance Secure VNet"
} # Change this to the tags you want to use for your resources

# VNet 
address_space = "10.0.0.0/16" # Change this to the address space you want to use, make sure it does not conflict with other VNets

dns_servers = [] # Change this if you require custom DNS settings for hybrid connectivity to your on-premises network

default_subnet_name = "default" # Change this to the name of the subnet you want to use for Azure SQL Database Managed Instance

default_subnet_prefix = "10.0.0.0/24" # Change this to the address space you want to use for the Azure SQL Database Managed Instance subnet, must be contained within vnet address_space

sqlmi_subnet_name = "sqlmi" # Change this to the name of the subnet you want to use for Azure SQL Database Managed Instance

sqlmi_subnet_prefix = "10.0.1.0/24" # Change this to the address space you want to use for the Azure SQL Database Managed Instance subnet, must be contained within vnet address_space

