### Testing Variables ###
location                         = "westeurope"
resource_group_name              = "dns-resolver-test"
virtual_network_name             = "dns-resolver"
virtual_network_address_space    = ["10.1.0.0/23"]
inbound_subnet_address_prefixes  = ["10.1.0.0/24"]
outbound_subnet_address_prefixes = ["10.1.1.0/24"]
dns_resolver_name                = "test-dns-private-resolver"
tags = {
  Configuration = "Terraform"
}


