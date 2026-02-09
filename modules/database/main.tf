# ============================================================================
# MODULE: SQL DATABASE
# ============================================================================

# Random suffix for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Random password for SQL admin
resource "random_password" "sql_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# SQL Server
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = random_password.sql_admin_password.result
  minimum_tls_version          = "1.2"

  tags = var.tags
}

# SQL Database with HA settings
resource "azurerm_mssql_database" "main" {
  name           = "sqldb-quotes-${var.environment}"
  server_id      = azurerm_mssql_server.main.id
  sku_name       = var.sql_database_sku
  max_size_gb    = var.sql_database_sku == "Basic" ? 2 : 250
  zone_redundant = false  # Zone redundancy not available in eastus2 for S1 tier

  # Short term backup retention (7-35 days)
  short_term_retention_policy {
    retention_days           = var.sql_database_sku == "Basic" ? 7 : 35
    backup_interval_in_hours = 12
  }

  # Long term backup retention (only for Standard/Premium)
  dynamic "long_term_retention_policy" {
    for_each = var.sql_database_sku != "Basic" ? [1] : []
    content {
      weekly_retention  = "P12W"  # Keep weekly backups for 12 weeks
      monthly_retention = "P12M"  # Keep monthly backups for 12 months
      yearly_retention  = "P5Y"   # Keep yearly backups for 5 years
      week_of_year      = 1       # Week of year for yearly backup
    }
  }

  tags = var.tags
}

# Firewall Rule: Allow your IP
resource "azurerm_mssql_firewall_rule" "allow_my_ip" {
  name             = "AllowMyIP"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.my_ip_address
  end_ip_address   = var.my_ip_address
}

# Firewall Rule: Allow Azure Services
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
