# Provision a new spoke virtual network and related subnets for deploying Azure SQL Managed Insatance

# Providers used in this configuration

provider "azurerm" {
# subscription_id = "REPLACE-WITH-YOUR-SUBSCRIPTION-ID"
# client_id       = "REPLACE-WITH-YOUR-CLIENT-ID"
# client_secret   = "REPLACE-WITH-YOUR-CLIENT-SECRET"
# tenant_id       = "REPLACE-WITH-YOUR-TENANT-ID"
}

# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_prefix}-rg"
  location = "${var.location}"
  tags     = "${var.tags}"
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
  dns_servers         = "${var.dns_servers}"
  tags                = "${var.tags}"
}

# Create subnets
# Documentation:
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-determine-size-vnet-subnet

resource "azurerm_subnet" "defaultsubnet" {
  name                 = "${var.default_subnet_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.default_subnet_prefix}"
}

resource "azurerm_subnet" "sqlmisubnet" {
  name                 = "${var.sqlmi_subnet_name}"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.sqlmi_subnet_prefix}"
}

# Create network security group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.resource_prefix}-nsg"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  tags                = "${var.tags}"
}

# Create network security group rules 
# Documentation: 
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture#mandatory-inbound-security-rules 
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-find-management-endpoint-ip-address 
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-management-endpoint-verify-built-in-firewall
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture#mandatory-outbound-security-rules 
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-connectivity-architecture#connection-policy 
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-auto-failover-group#enabling-geo-replication-between-managed-instances-and-their-vnets 

resource "azurerm_network_security_rule" "allow_management_inbound" {
  name                        = "allow_management_inbound"
  description                 = "Allow inbound control plane traffic (management service endpoints)"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["9000", "9003","1438","1440", "1452"]
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_misubnet_inbound" {
  name                        = "allow_misubnet_inbound"
  description                 = "Allow all inbound traffic originating from the subnet"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "${azurerm_subnet.sqlmisubnet.address_prefix}"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_health_probe_inbound" {
  name                        = "allow_health_probe_inbound"
  description                 = "Allow inbound control plane traffic (health service endpoints)"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "AzureLoadBalancer"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_tds_inbound" {
  name                        = "allow_tds_inbound"
  description                 = "Allow inbound data plane traffic (TDS clients e.g. ODBC, OLE DB, ADO.NET)"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_range      = "1433"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_redirect_inbound" {
  name                        = "allow_redirect_inbound"
  description                 = "Allows inbound data plane traffic to be redirected to specific managed instance node where database is located"
  priority                    = 1100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_range      = "11000-11999"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_geodr_inbound" {
  name                        = "allow_geodr_inbound"
  description                 = "Allow inbound geodr traffic"
  priority                    = 1200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_port_range      = "5022"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny_all_inbound"
  description                 = "Deny all other inbound traffic"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_management_outbound" {
  name                        = "allow_management_outbound"
  description                 = "Allow outbound control plane traffic (management service endpoints)"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_ranges     = ["80", "443", "12000"]
  destination_address_prefix  = "AzureCloud"   
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_misubnet_outbound" {
  name                        = "allow_misubnet_outbound"
  description                 = "Allow all outbound traffic originating from the subnet"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "*"
  destination_address_prefix  = "${azurerm_subnet.sqlmisubnet.address_prefix}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_tds_outbound" {
  name                        = "allow_tds_outbound"
  description                 = "Allow outbound data plane traffic from the subnet (TDS / linked servers)"
  priority                    = 1000
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "1433"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_redirect_outbound" {
  name                        = "allow_redirect_outbound"
  description                 = "Allows outbound data plane traffic from redirected managed instance nodes where a database is located"
  priority                    = 1100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "11000-11999"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "allow_geodr_outbound" {
  name                        = "allow_geodr_outbound"
  description                 = "Allows outbound storage layer traffic (geodr)"
  priority                    = 1200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  source_address_prefix       = "*"
  destination_port_range      = "5022"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}

resource "azurerm_network_security_rule" "deny_all_outbound" {
  name = "deny_all_outbound"
  description = "Deny all other outbound traffic"
  priority = 4096
  direction = "Outbound"
  access = "Deny"
  protocol = "*"
  source_port_range = "*"
  source_address_prefix = "*"
  destination_port_range = "*"
  destination_address_prefix = "*"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  network_security_group_name = "${azurerm_network_security_group.nsg.name}"
}
resource "azurerm_subnet_network_security_group_association" "subnet_to_nsg" {
  subnet_id                 = "${azurerm_subnet.sqlmisubnet.id}"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

# Create user defined routes
# Documentation:
#   https://docs.microsoft.com/en-us/azure/sql-database/sql-database-managed-instance-connectivity-architecture#user-defined-routes

resource "azurerm_route_table" "routetable" {
  name                          = "${var.resource_prefix}-rt"
  location                      = "${azurerm_resource_group.rg.location}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  disable_bgp_route_propagation = false

  tags = "${var.tags}"
}

resource "azurerm_route" "subnet_to_vnetlocal" {
    name = "subnet_to_vnetlocal"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "${azurerm_subnet.sqlmisubnet.address_prefix}"
    next_hop_type = "VnetLocal"
}

resource "azurerm_route" "mi-0-5-nexthop-internet" {
    name = "mi-0-5-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "0.0.0.0/5"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-8-7-nexthop-internet" {
    name = "mi-8-7-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "8.0.0.0/7"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-11-8-nexthop-internet" {
    name = "mi-11-8-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "11.0.0.0/8"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-12-6-nexthop-internet" {
    name = "mi-12-6-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "12.0.0.0/6"
    next_hop_type = "Internet"
}
resource "azurerm_route" "mi-16-4-nexthop-internet" {
    name = "mi-16-4-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "16.0.0.0/4"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-32-3-nexthop-internet" {
    name = "mi-32-3-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "32.0.0.0/3"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-64-2-nexthop-internet" {
    name = "mi-64-2-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "64.0.0.0/2"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-128-3-nexthop-internet" {
    name = "mi-128-3-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "128.0.0.0/3"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-160-5-nexthop-internet" {
    name = "mi-160-5-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "160.0.0.0/5"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-168-6-nexthop-internet" {
    name = "mi-168-6-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "168.0.0.0/6"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-172-12-nexthop-internet" {
    name = "mi-172-12-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "172.0.0.0/12"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-172-32-11-nexthop-internet" {
    name = "mi-172-32-11-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "172.32.0.0/11"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-172-64-10-nexthop-internet" {
    name = "mi-172-64-10-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "172.64.0.0/10"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-172-128-9-nexthop-internet" {
    name = "mi-172-128-9-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "172.128.0.0/9"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-173-8-nexthop-internet" {
    name = "mi-173-8-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "173.0.0.0/8"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-174-7-nexthop-internet" {
    name = "mi-174-7-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "174.0.0.0/7"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-176-4-nexthop-internet" {
    name = "mi-176-4-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "176.0.0.0/4"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-9-nexthop-internet" {
    name = "mi-192-9-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.0.0.0/9"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-128-11-nexthop-internet" {
    name = "mi-192-128-11-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.128.0.0/11"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-160-13-nexthop-internet" {
    name = "mi-192-160-13-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.160.0.0/13"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-169-16-nexthop-internet" {
    name = "mi-192-169-16-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.169.0.0/16"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-170-15-nexthop-internet" {
    name = "mi-192-170-15-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.170.0.0/15"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-172-14-nexthop-internet" {
    name = "mi-192-172-14-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.172.0.0/14"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-176-12-nexthop-internet" {
    name = "mi-192-176-12-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.176.0.0/12"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-192-192-10-nexthop-internet" {
    name = "mi-192-192-10-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "192.192.0.0/10"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-193-8-nexthop-internet" {
    name = "mi-193-8-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "193.0.0.0/8"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-194-7-nexthop-internet" {
    name = "mi-194-7-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "194.0.0.0/7"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-196-6-nexthop-internet" {
    name = "mi-196-6-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "196.0.0.0/6"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-200-5-nexthop-internet" {
    name = "mi-200-5-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "200.0.0.0/5"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-208-4-nexthop-internet" {
    name = "mi-208-4-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "208.0.0.0/4"
    next_hop_type = "Internet"
}

resource "azurerm_route" "mi-224-3-nexthop-internet" {
    name = "mi-224-3-nexthop-internet"
    resource_group_name = "${azurerm_resource_group.rg.name}"
    route_table_name = "${azurerm_route_table.routetable.name}"
    address_prefix = "224.0.0.0/3"
    next_hop_type = "Internet"
}

resource "azurerm_subnet_route_table_association" "subnet_to_routetable" {
  subnet_id      = "${azurerm_subnet.sqlmisubnet.id}"
  route_table_id = "${azurerm_route_table.routetable.id}"
}
