variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "sql_admin_username" {
  description = "Administrator username for SQL Server"
  type        = string
}

variable "sql_database_sku" {
  description = "SKU for SQL Database"
  type        = string
}

variable "my_ip_address" {
  description = "Your IP address for SQL firewall rule"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
