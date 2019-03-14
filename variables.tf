# General 
variable "resource_prefix" {
  type = "string"
  description = "The prefix used for all resources in this example"
  default     = "sqlmi-secure-vnet"
}

variable "location" {
  type = "string"
  description = "The Azure Region in which the resources in this example should exist"
  default     = "West US 2"
}

variable "tags" {
  type        = "map"
  description = "Any tags which should be assigned to the resources in this plan"

  default = {
    environment = "Unknown"
    costcenter  = "Unknown"
    project     = "Unknown"
  }
}

# VNet 
variable "address_space" {
  type = "string"
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
}

variable "dns_servers" {
  type = "list"
  description = "The DNS servers to be used by the virtual network"
  default     = []
}

variable "default_subnet_prefix" {
  type = "string"
  description = "The address prefix to use for the default subnet."
  default     = "10.0.0.0/24"
}

variable "default_subnet_name" {
  type = "string"
  description = "The name to use for the default subnet."
  default     = "default"
}
variable "sqlmi_subnet_prefix" {
  type = "string"
  description = "The address prefix to use for the SQL Managed Instance subnet."
  default     = "10.0.1.0/24"
}

variable "sqlmi_subnet_name" {
  type = "string"
  description = "The name to use for the Azure SQL Managed Instance subnet."
  default     = "sqlmi"
}
