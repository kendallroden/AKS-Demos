resource "azurerm_resource_group" "hub" {
	provider = azurerm.hub
  	name = "${local.prefix}hub-rg"
  	location = local.location
}

resource "azurerm_virtual_network" "hub" {
	provider = azurerm.hub
	name = "${local.prefix}hub-vnet"
	resource_group_name = azurerm_resource_group.hub.name
	location = azurerm_resource_group.hub.location
	address_space       = [var.hub_address_space]
}

resource azurerm_subnet aks {
	provider = azurerm.hub
	name = "AksSubnet"
	resource_group_name  = azurerm_resource_group.hub.name
	virtual_network_name = azurerm_virtual_network.hub.name
	address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub.address_space[0], 6, 1)]
}

resource "azurerm_subnet" "hub-pe" {
	provider = azurerm.hub
	name = "StoragePeSubnet"
	resource_group_name  = azurerm_resource_group.hub.name
	virtual_network_name = azurerm_virtual_network.hub.name
	address_prefixes     = [cidrsubnet(azurerm_virtual_network.hub.address_space[0], 8, 0)]
	enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_virtual_network_peering" "hubtospoke" {
	provider = azurerm.hub
	name                      = "hubtospoke"
	resource_group_name       = azurerm_resource_group.hub.name
	virtual_network_name      = azurerm_virtual_network.hub.name
	remote_virtual_network_id = azurerm_virtual_network.spoke.id
}