terraform {
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

#########################################
# Pre Requisites for the module testing #
#########################################

# Creating Random id to append to the resource group name
resource "random_id" "rg" {
  byte_length = 8
}

resource "azurerm_resource_group" "dns_resolver" {
  name     = lower("rg-${var.resource_group_name}-${random_id.rg.hex}")
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = lower("vnet-${var.virtual_network_name}")
  address_space       = var.virtual_network_address_space
  resource_group_name = azurerm_resource_group.dns_resolver.name
  location            = var.location
}

# Creating Inbound Subnet, note there is only support for two inbound endpoints per DNS Resolver, and they cannot share the same subnet.
resource "azurerm_subnet" "inbound" {
  name                 = lower("snet-${trimprefix(azurerm_virtual_network.vnet.name, "vnet-")}-inbound")
  address_prefixes     = var.inbound_subnet_address_prefixes
  resource_group_name  = azurerm_resource_group.dns_resolver.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

# Creating Outbound Subnet, note there is only support for two outbound endpoints per DNS Resolver, and they cannot share the same subnet.
resource "azurerm_subnet" "outbound" {
  name                 = lower("snet-${trimprefix(azurerm_virtual_network.vnet.name, "vnet-")}-outbound")
  address_prefixes     = var.outbound_subnet_address_prefixes
  resource_group_name  = azurerm_resource_group.dns_resolver.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

##################################################
# MODULE TO TEST                                 #
##################################################

module "dns-private-resolver" {
  source              = "../.."
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_resolver_name   = var.dns_resolver_name
  virtual_network_id  = azurerm_virtual_network.vnet.id
  tags                = var.tags

  dns_resolver_inbound_endpoints = [
    # There is currently only support for two Inbound endpoints per Private Resolver.
    {
      inbound_endpoint_name = "inbound"
      inbound_subnet_id     = azurerm_subnet.inbound.id
    }
  ]

  dns_resolver_outbound_endpoints = [
    # There is currently only support for two Outbound endpoints per Private Resolver.
    {
      outbound_endpoint_name = "outbound"
      outbound_subnet_id     = azurerm_subnet.outbound.id
      forwarding_rulesets = [
        # There is currently only support for two DNS forwarding rulesets per outbound endpoint.
        {
          forwarding_ruleset_name = "default-ruleset"
        }
      ]
    }
  ]
}