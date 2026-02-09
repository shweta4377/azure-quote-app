# ============================================================================
# MODULE: CONTAINER REGISTRY (ACR)
# ============================================================================

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_container_registry" "main" {
  name                = "acr${var.project_name}${var.environment}${random_string.suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = var.tags
}
