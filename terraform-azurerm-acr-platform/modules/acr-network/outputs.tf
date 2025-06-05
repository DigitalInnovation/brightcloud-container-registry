output "private_endpoint" {
  description = "Private endpoint configuration"
  value = var.create_private_endpoint ? {
    id                = azurerm_private_endpoint.acr_pe[0].id
    name              = azurerm_private_endpoint.acr_pe[0].name
    private_ip_address = azurerm_private_endpoint.acr_pe[0].private_service_connection[0].private_ip_address
    fqdn              = azurerm_private_endpoint.acr_pe[0].private_dns_zone_configs[0].record_sets[0].fqdn
  } : null
}

output "private_dns_zone" {
  description = "Private DNS zone configuration"
  value = var.create_private_endpoint ? {
    id   = azurerm_private_dns_zone.acr_dns[0].id
    name = azurerm_private_dns_zone.acr_dns[0].name
  } : null
}

output "application_security_group" {
  description = "Application security group for ACR clients"
  value = var.create_application_security_group ? {
    id   = azurerm_application_security_group.acr_clients[0].id
    name = azurerm_application_security_group.acr_clients[0].name
  } : null
}

output "network_security_rules" {
  description = "Network security rules created"
  value = {
    inbound_rule_created = var.network_security_group_name != null
    asg_rule_created     = var.create_application_security_group && var.network_security_group_name != null
  }
}