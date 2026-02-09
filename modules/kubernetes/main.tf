# ============================================================================
# MODULE: KUBERNETES (AKS)
# ============================================================================

data "azurerm_client_config" "current" {}

resource "random_string" "aks_suffix" {
  length  = 4
  special = false
  upper   = false
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Azure Kubernetes Service Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}-${var.environment}-${random_string.aks_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version != "" ? var.kubernetes_version : null

  # Default node pool with HA configuration
  default_node_pool {
    name               = "default"
    vm_size            = var.aks_node_size
    vnet_subnet_id     = var.aks_subnet_id
    os_disk_size_gb    = 30
    auto_scaling_enabled = true  # Changed from enable_auto_scaling in v4
    min_count          = var.aks_min_node_count
    max_count          = var.aks_max_node_count
    node_count         = null
    zones              = ["1", "2", "3"]  # Spread across availability zones for HA

    node_labels = {
      "environment" = var.environment
      "workload"    = "general"
    }

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Network configuration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  # Enable Azure Monitor Container Insights
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }

  # Automatic upgrades
  automatic_upgrade_channel = "stable"  # Changed from automatic_channel_upgrade in v4

  # Disable Azure RBAC - use standard Kubernetes RBAC for easier access
  # azure_active_directory_role_based_access_control {
  #   azure_rbac_enabled = false
  #   tenant_id          = data.azurerm_client_config.current.tenant_id
  # }

  # Enable workload identity for Key Vault integration (not needed with k8s secrets)
  # oidc_issuer_enabled       = true
  # workload_identity_enabled = true

  tags = var.tags
}

# Role assignment to allow AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
