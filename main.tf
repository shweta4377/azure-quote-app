# ============================================================================
# MAIN TERRAFORM CONFIGURATION
# ============================================================================
# Azure SQL + AKS Unified Deployment with High Availability

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

provider "azurerm" {
  subscription_id            = "da656374-14fd-4c1e-89d7-3a80e55205de"
  skip_provider_registration = true  # Skip automatic resource provider registration

  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ============================================================================
# LOCALS
# ============================================================================
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Student"
    Purpose     = "Learning"
    Deployment  = "Unified"
    CostCenter  = "Engineering"
  }
}

# ============================================================================
# RESOURCE GROUP
# ============================================================================
module "resource_group" {
  source = "./modules/resource-group"

  project_name = var.project_name
  environment  = var.environment
  location     = var.location
  tags         = local.common_tags
}

# ============================================================================
# NETWORKING
# ============================================================================
module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  vnet_address_space  = var.vnet_address_space
  aks_subnet_prefix   = var.aks_subnet_prefix
  appgw_subnet_prefix = var.appgw_subnet_prefix
  pe_subnet_prefix    = var.pe_subnet_prefix
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

# ============================================================================
# CONTAINER REGISTRY
# ============================================================================
module "acr" {
  source = "./modules/acr"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

# ============================================================================
# SQL DATABASE
# ============================================================================
module "database" {
  source = "./modules/database"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  sql_admin_username  = var.sql_admin_username
  sql_database_sku    = var.sql_database_sku
  my_ip_address       = var.my_ip_address
  tags                = local.common_tags

  depends_on = [module.resource_group]
}

# ============================================================================
# KUBERNETES (AKS)
# ============================================================================
module "aks" {
  source = "./modules/kubernetes"

  project_name         = var.project_name
  environment          = var.environment
  location             = var.location
  resource_group_name  = module.resource_group.name
  aks_subnet_id        = module.networking.aks_subnet_id
  aks_node_size        = var.aks_node_size
  aks_min_node_count   = var.aks_min_node_count
  aks_max_node_count   = var.aks_max_node_count
  kubernetes_version   = var.kubernetes_version
  acr_id               = module.acr.acr_id
  tags                 = local.common_tags

  depends_on = [module.networking, module.acr]
}

# ============================================================================
# APPLICATION GATEWAY
# ============================================================================
module "app_gateway" {
  source = "./modules/app-gateway"

  project_name        = var.project_name
  environment         = var.environment
  location            = var.location
  resource_group_name = module.resource_group.name
  appgw_subnet_id     = module.networking.appgw_subnet_id
  backend_address     = var.backend_address
  waf_enabled         = var.waf_enabled
  waf_mode            = var.waf_mode
  appgw_capacity_min  = var.appgw_capacity_min
  appgw_capacity_max  = var.appgw_capacity_max
  tags                = local.common_tags

  depends_on = [module.networking]
}
