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
  resource_group_name = azurerm_resource_group.dns_resolver.name
  location            = azurerm_resource_group.dns_resolver.location
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

###########################################################
# Testing rule creation within the rule set created above #
###########################################################

resource "azurerm_private_dns_resolver_forwarding_rule" "corp_mycompany_com" {
  name                      = "corp_mycompany_com" # Can only contain letters, numbers, underscores, and/or dashes, and should start with a letter.
  dns_forwarding_ruleset_id = module.dns-private-resolver.dns_resolver.dns_outbound_endpoints.outbound.dns_forwarding_rulesets.outbound-default-ruleset.ruleset_id
  domain_name               = "corp.mycompany.com." # Domain name supports 2-34 lables and must end with a dot (period) for example corp.mycompany.com. has three lables.
  enabled                   = true
  target_dns_servers {
    ip_address = "10.0.0.3"
    port       = 53
  }
  target_dns_servers {
    ip_address = "10.0.0.4"
    port       = 53
  }

  depends_on = [
    module.dns-private-resolver
  ]
}

##################################################################################
# Testing: Adding Inbound Endpoint private ip as Custom DNS Server Configuration #
##################################################################################

resource "azurerm_virtual_network" "vnet_custom_dns" {
  name                = "vnet-custom-dns-server-${random_id.rg.hex}"
  location            = azurerm_resource_group.dns_resolver.location
  resource_group_name = azurerm_resource_group.dns_resolver.name
  address_space       = ["10.0.0.0/16"]
  dns_servers         = [module.test.dns-private-resolver.dns_inbound_endpoints.inbound.inbound_endpoint_private_ip_address]
}