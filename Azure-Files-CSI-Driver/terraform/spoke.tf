resource "azurerm_resource_group" "spoke" {
	provider = azurerm.spoke
  	name = "${local.prefix}spoke-rg"
  	location = local.location
}

resource "azurerm_virtual_network" "spoke" {
	provider = azurerm.spoke
	name = "${local.prefix}spoke-vnet"
	resource_group_name = azurerm_resource_group.spoke.name
	location = azurerm_resource_group.spoke.location
	address_space       = [var.spoke_address_space]
}

resource "azurerm_subnet" "spoke-pe" {
	provider = azurerm.spoke
	name = "StoragePeSubnet"
	resource_group_name  = azurerm_resource_group.spoke.name
	virtual_network_name = azurerm_virtual_network.spoke.name
	address_prefixes     = [cidrsubnet(azurerm_virtual_network.spoke.address_space[0], 8, 0)]
	enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_virtual_network_peering" "spoketohub" {
	provider = azurerm.spoke
	name                      = "spoketohub"
	resource_group_name       = azurerm_resource_group.spoke.name
	virtual_network_name      = azurerm_virtual_network.spoke.name
	remote_virtual_network_id = azurerm_virtual_network.hub.id
}

resource "azurerm_storage_account" "spoke" {
  provider = azurerm.spoke
  name                     = "${local.prefix}spokesa"
  resource_group_name      = azurerm_resource_group.spoke.name
  location                 = azurerm_resource_group.spoke.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "spoke" {
  provider = azurerm.spoke
  name                 = "${local.prefix}fs"
  storage_account_name = azurerm_storage_account.spoke.name
  quota                = 5120
}

resource "azurerm_private_dns_zone" "priv-dns-spoke" {
	provider = azurerm.spoke
	name                = "privatelink.file.core.windows.net"
	resource_group_name = azurerm_resource_group.spoke.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-spoke" {
	provider = azurerm.spoke
	name                  = "priv-link-spoke"
	resource_group_name   = azurerm_resource_group.spoke.name
	private_dns_zone_name = azurerm_private_dns_zone.priv-dns-spoke.name
	virtual_network_id    = azurerm_virtual_network.spoke.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-hub" {
	provider = azurerm.spoke
	name                  = "priv-link-hub"
	resource_group_name   = azurerm_resource_group.spoke.name
	private_dns_zone_name = azurerm_private_dns_zone.priv-dns-spoke.name
	virtual_network_id    = azurerm_virtual_network.hub.id
}

resource "azurerm_private_endpoint" "storage-spoke" {
	provider = azurerm.spoke
	name = "pe-storage-spoke"
	location = azurerm_resource_group.spoke.location
	resource_group_name = azurerm_resource_group.spoke.name
	subnet_id = azurerm_subnet.spoke-pe.id

  private_service_connection {
	name = "storage-privateserviceconnection"
	is_manual_connection = false
	private_connection_resource_id = azurerm_storage_account.spoke.id
	subresource_names = ["file"]
  }

   private_dns_zone_group {
    name                  = "storage-dns-group"
    private_dns_zone_ids  = [ azurerm_private_dns_zone.priv-dns-spoke.id ]
  }
}