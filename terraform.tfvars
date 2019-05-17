# Modify this file to customize the Azure SQL Managed Instance network configuration for your specific environment

# General 
resource_prefix = "sqlmi-preprod" # Change this to a prefix that complies with your resource naming conventions

location = "East US" # Change this to the region you want to deploy 

tags = {
  environment = "preprod"
  costcenter  = "unknown"
  project     = "Azure SQL Managed Instance pre-production testing"
} # Change this to the tags you want to use for your resources

# Virtual network 
address_space = "10.0.0.0/16" # Change this to the address space you want to use, make sure it does not conflict with other VNets

dns_servers = [] # Change this if you require custom DNS settings for hybrid connectivity to your on-premises network

# Subnets
default_subnet_name = "default" # Change this to the name of the default subnet

default_subnet_prefix = "10.0.0.0/24" # Change this to the address space you want to use for the default subnet

sqlmi_subnet_name = "sqlmi" # Change this to the name of the subnet you want to use for the Azure SQL Database Managed Instance deployment

sqlmi_subnet_prefix = "10.0.1.0/24" # Change this to the address space you want to use for the Azure SQL Database Managed Instance subnet
