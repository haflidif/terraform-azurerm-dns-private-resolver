##################################################
# VARIABLES                                      #
##################################################
variable "location" {
  type        = string
  default     = "westeurope"
  description = "Region / Location where Azure DNS Resolver should be deployed"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the Resource Group where resources are deployed"
}

variable "virtual_network_name" {
  type        = string
  default     = "dns-resolver"
  description = "Virtual Network Name"
}

variable "virtual_network_address_space" {
  type        = list(string)
  default     = ["10.1.0.0/23"]
  description = "List of all virtual network addresses"
}

variable "inbound_subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.1.0.0/24"]
  description = "List of inbound subnet address prefixes"
}

variable "outbound_subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.1.1.0/24"]
  description = "List of outbound subnet address prefixes"
}

variable "dns_resolver_name" {
  type        = string
  description = "Name of the Azure DNS Private Resolver"
}

variable "tags" {
  type        = map(string)
  description = "(Optional): Resource Tags"
  default     = {}
}