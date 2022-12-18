# Module: Azure DNS Private Resolver

## Description
Create Azure DNS Private Resolver with Inbound / Outbound endpoints as well as DNS Forwarding rule sets using Terraform.

To learn more about Azure DNS Private Reslover is check out Microsoft Learn: [What is Azure DNS Private Resolver?](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview)

This Module can be used to create Azure DNS Private Resolver, one or two Inbound and Outbound Endpoints as well as one or two DNS Forwarding rule sets due to the limitations in supporting more then two Inbound/Outbound Endpoints and two DNS forwarding rule sets per Outbound Endpoint giving us total of four DNS Forwarding rule sets available, with two outbound endpoints.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.36.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.36.0 |

## Resources


- [azurerm_private_dns_resolver.private_dns_resolver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver) 
- [azurerm_private_dns_resolver_dns_forwarding_ruleset.forwarding_ruleset](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_dns_forwarding_ruleset)
- [azurerm_private_dns_resolver_inbound_endpoint.private_dns_resolver_inbound_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_inbound_endpoint)
- [azurerm_private_dns_resolver_outbound_endpoint.private_dns_resolver_outbound_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_outbound_endpoint)

## Module Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required): Name of the resource group where resources should be deployed. | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | (Required): Region / Location where Azure DNS Resolver should be deployed | `string` | n/a | yes |
| <a name="input_dns_resolver_name"></a> [dns\_resolver\_name](#input\_dns\_resolver\_name) | (Required): Name of the Azure DNS Private Resolver | `string` | n/a | yes |
| <a name="input_virtual_network_id"></a> [virtual\_network\_id](#input\_virtual\_network\_id) | (Required): ID of the associated virtual network | `string` | n/a | yes |
| <a name="input_dns_resolver_inbound_endpoints"></a> [dns\_resolver\_inbound\_endpoints](#input\_dns\_resolver\_inbound\_endpoints) | (Optional): Set of Azure Private DNS resolver Inbound Endpoints | <pre>set(object({<br>    inbound_endpoint_name = string<br>    inbound_subnet_id     = string<br>  }))</pre> | `[]` | no |
| <a name="input_dns_resolver_outbound_endpoints"></a> [dns\_resolver\_outbound\_endpoints](#input\_dns\_resolver\_outbound\_endpoints) | (Optional): Set of Azure Private DNS resolver Outbound Endpoints with one or more Forwarding Rule sets | <pre>set(object({<br>    outbound_endpoint_name = string<br>    outbound_subnet_id     = string<br>    forwarding_rulesets = optional(set(object({<br>      forwarding_ruleset_name = optional(string)<br>    })))<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional): Resource Tags | `map(string)` | `{}` | no |


## Module Outputs

There is only one Output attribute, but it exports multiple information described in the value column down below.

To get the information needed for example to get the DNS Forwarding Rule Set id to be able to add dns forwarding rules seperatly you can use (Let's say that the module name is `dns_resolver_weu`, your outbound endpoint name is `outbound` and your rule set name is `default-ruleset` ): `module.dns_resolver_weu.dns_resolver.dns_outbound_endpoints.outbound.dns_forwarding_rulesets.outbound-default-ruleset.ruleset_id` will give you the ID of the dns forwarding rule set needed to add DNS forwarding rule into the forwarding rule set using [azurerm_private_dns_resolver_forwarding_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_forwarding_rule) see [Example](#example-2) below.

| Name | Description | Value | Sensitive |
|------|-------------|-------|:---------:|
| <a name="output_dns_resolver"></a> [dns\_resolver](#output\_dns\_resolver) | Multi value Output that includes all information needed to use values from the module. | <pre>{<br>  "dns_inbound_endpoints": {<br>    "inbound": {<br>      "inbound_endpoint_id": "/subscriptions/01234567-abcd-efgh-ijkl-891011121314/resourceGroups/rg-dns-resolver-test-06076545238c8c77/providers/Microsoft.Network/dnsResolvers/test-private-dns-resolver/inboundEndpoints/inbound",<br>      "inbound_endpoint_name": "inbound"<br>    }<br>  },<br>  "dns_outbound_endpoints": {<br>    "outbound": {<br>      "dns_forwarding_rulesets": {<br>        "outbound-default-ruleset": {<br>          "ruleset_id": "/subscriptions/01234567-abcd-efgh-ijkl-891011121314/resourceGroups/rg-dns-resolver-test-06076545238c8c77/providers/Microsoft.Network/dnsForwardingRulesets/default-ruleset",<br>          "ruleset_name": "default-ruleset"<br>        }<br>      },<br>      "outbound_endpoint_id": "/subscriptions/01234567-abcd-efgh-ijkl-891011121314/resourceGroups/rg-dns-resolver-test-06076545238c8c77/providers/Microsoft.Network/dnsResolvers/test-private-dns-resolver/outboundEndpoints/outbound",<br>      "outbound_endpoint_name": "outbound"<br>    }<br>  },<br>  "dns_resolver_id": "/subscriptions/01234567-abcd-efgh-ijkl-891011121314/resourceGroups/rg-dns-resolver-test-06076545238c8c77/providers/Microsoft.Network/dnsResolvers/test-private-dns-resolver"<br>}</pre> | no |


## Example Usage

### Example 1
Creating Azure Private DNS Resolver, Inbound & Outbound Endpoint plus DNS Forwarding Rule set.
For this example the pre-requisites of Resource Group, Virtual Network, 1x Inbound Subnet, and 1x Outbound subnet have already been declared in the code, and is not included in the example, to create the resouces needed for this example checkout my other module on creating Virtual Network and Subnets: [terraform-azurerm-network](https://github.com/haflidif/terraform-azurerm-network)

```hcl
#..omitted

module "dns_private_resolver" {
  source              = "github.com/haflidif/terraform-azurerm-dns-private-resolver"
  resource_group_name = azurerm_resource_group.dns_resolver.name
  location            = azurerm_resource_group.dns_resolver.location
  dns_resolver_name   = "test-private-dns-resolver"
  virtual_network_id  = azurerm_virtual_network.vnet.id
  tags = {
    Configuration = "Terraform"
  }

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
```

### Example 2 
In this example we are going to use the module output for the DNS Forwarding Rule set created in [Example 1](#example-1) to add a DNS Forwarding rule to the rule set outside of the module using [azurerm_private_dns_resolver_forwarding_rule](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_resolver_forwarding_rule) each ruleset can have up to 25 rules see [restrictions](https://learn.microsoft.com/en-us/azure/dns/dns-private-resolver-overview#restrictions)

Each rule includes one or more target DNS Servers divided by block as seen below.

```hcl
#..omitted

resource "azurerm_private_dns_resolver_forwarding_rule" "corp_mycompany_com" {
  name                      = "corp_mycompany_com" # 
  dns_forwarding_ruleset_id = module.dns_private_resolver.dns_resolver.dns_outbound_endpoints.outbound.dns_forwarding_rulesets.default-ruleset.ruleset_id
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
}

```