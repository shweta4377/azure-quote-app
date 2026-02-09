# ============================================================================
# MODULE: APPLICATION GATEWAY
# ============================================================================

# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.project_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.project_name}-${var.environment}-appgw"
  tags                = var.tags
}

# WAF Policy
resource "azurerm_web_application_firewall_policy" "main" {
  count               = var.waf_enabled ? 1 : 0
  name                = "wafpolicy-${var.project_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location

  policy_settings {
    enabled                     = true
    mode                        = var.waf_mode
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }

  tags = var.tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = var.appgw_capacity_min
    max_capacity = var.appgw_capacity_max
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name         = "backend-pool"
    ip_addresses = [var.backend_address]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    probe_name            = "health-probe"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  probe {
    name                = "health-probe"
    protocol            = "Http"
    path                = "/health"
    host                = var.backend_address
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    match {
      status_code = ["200-399"]
    }
  }

  firewall_policy_id = var.waf_enabled ? azurerm_web_application_firewall_policy.main[0].id : null

  # SSL Policy - Use modern TLS 1.2 minimum
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"  # Modern TLS 1.2+ policy
  }

  tags = var.tags
}
