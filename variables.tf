# ============================================================================
# VARIABLES
# ============================================================================

# ----------------------------------------------------------------------------
# General Settings
# ----------------------------------------------------------------------------
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "quoteapp"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "learning"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

# ----------------------------------------------------------------------------
# Networking
# ----------------------------------------------------------------------------
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "aks_subnet_prefix" {
  description = "Address prefix for AKS subnet"
  type        = string
  default     = "10.0.0.0/22"
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "pe_subnet_prefix" {
  description = "Address prefix for Private Endpoints subnet"
  type        = string
  default     = "10.0.5.0/24"
}

# ----------------------------------------------------------------------------
# SQL Database
# ----------------------------------------------------------------------------
variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
  default     = "sqladmin"
}

variable "sql_database_sku" {
  description = "SKU for SQL Database (Basic, S1, S2, P1, etc.)"
  type        = string
  default     = "S1"
}

variable "my_ip_address" {
  description = "Your IP address for SQL firewall rule"
  type        = string
}

# ----------------------------------------------------------------------------
# Kubernetes (AKS)
# ----------------------------------------------------------------------------
variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes for AKS cluster"
  type        = number
  default     = 2
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes for AKS cluster"
  type        = number
  default     = 5
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave empty for latest)"
  type        = string
  default     = ""
}

# ----------------------------------------------------------------------------
# Application Gateway
# ----------------------------------------------------------------------------
variable "backend_address" {
  description = "Backend IP address for Application Gateway"
  type        = string
  default     = "10.0.1.100"
}

variable "waf_enabled" {
  description = "Enable Web Application Firewall"
  type        = bool
  default     = true
}

variable "waf_mode" {
  description = "WAF mode (Detection or Prevention)"
  type        = string
  default     = "Prevention"
}

variable "appgw_capacity_min" {
  description = "Minimum capacity units for Application Gateway"
  type        = number
  default     = 2
}

variable "appgw_capacity_max" {
  description = "Maximum capacity units for Application Gateway"
  type        = number
  default     = 5
}
