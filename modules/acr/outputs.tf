output "acr_name" {
  description = "Name of the container registry"
  value       = azurerm_container_registry.main.name
}

output "acr_id" {
  description = "ID of the container registry"
  value       = azurerm_container_registry.main.id
}

output "acr_login_server" {
  description = "Login server for the container registry"
  value       = azurerm_container_registry.main.login_server
}
