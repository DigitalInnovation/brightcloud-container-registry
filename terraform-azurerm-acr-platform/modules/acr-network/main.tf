locals {
  private_endpoint_name = "${var.registry_name}-pe"
  dns_zone_name        = "privatelink.azurecr.io"
}

# Data source for existing container registry
data "azurerm_container_registry" "acr" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
}

# Data source for virtual network
data "azurerm_virtual_network" "vnet" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = var.vnet_resource_group_name
}

# Data source for subnet
data "azurerm_subnet" "subnet" {
  count                = var.create_private_endpoint ? 1 : 0
  name                 = var.subnet_name
  virtual_network_name = var.virtual_network_name
  resource_group_name  = var.vnet_resource_group_name
}

# Private endpoint for ACR
resource "azurerm_private_endpoint" "acr_pe" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = local.private_endpoint_name
  location            = data.azurerm_container_registry.acr.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.subnet[0].id

  private_service_connection {
    name                           = "${var.registry_name}-psc"
    private_connection_resource_id = data.azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "acr-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr_dns[0].id]
  }

  tags = var.tags
}

# Private DNS zone for ACR
resource "azurerm_private_dns_zone" "acr_dns" {
  count               = var.create_private_endpoint ? 1 : 0
  name                = local.dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link private DNS zone to virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "acr_dns_link" {
  count                 = var.create_private_endpoint ? 1 : 0
  name                  = "${var.registry_name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr_dns[0].name
  virtual_network_id    = data.azurerm_virtual_network.vnet[0].id
  registration_enabled  = false
  tags                  = var.tags
}

# Network security group rule for ACR access (if NSG is provided)
resource "azurerm_network_security_rule" "acr_inbound" {
  count                       = var.network_security_group_name != null ? 1 : 0
  name                        = "Allow-ACR-Inbound"
  priority                    = var.nsg_rule_priority
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = var.allowed_source_address_prefixes
  destination_address_prefix  = "*"
  resource_group_name         = var.vnet_resource_group_name
  network_security_group_name = var.network_security_group_name
}

# Application security group for ACR clients (optional)
resource "azurerm_application_security_group" "acr_clients" {
  count               = var.create_application_security_group ? 1 : 0
  name                = "${var.registry_name}-clients-asg"
  location            = data.azurerm_container_registry.acr.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Network security rule using application security group
resource "azurerm_network_security_rule" "acr_asg_inbound" {
  count                                      = var.create_application_security_group && var.network_security_group_name != null ? 1 : 0
  name                                       = "Allow-ACR-ASG-Inbound"
  priority                                   = var.nsg_rule_priority + 1
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_port_range                          = "*"
  destination_port_range                     = "443"
  source_application_security_group_ids      = [azurerm_application_security_group.acr_clients[0].id]
  destination_address_prefix                 = "*"
  resource_group_name                        = var.vnet_resource_group_name
  network_security_group_name                = var.network_security_group_name
}