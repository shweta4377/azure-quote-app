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

variable "appgw_subnet_id" {
  description = "ID of the Application Gateway subnet"
  type        = string
}

variable "backend_address" {
  description = "Backend IP address"
  type        = string
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
  description = "Minimum capacity units"
  type        = number
  default     = 2
}

variable "appgw_capacity_max" {
  description = "Maximum capacity units"
  type        = number
  default     = 5
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
