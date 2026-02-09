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

variable "aks_subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
}

variable "aks_min_node_count" {
  description = "Minimum number of nodes"
  type        = number
}

variable "aks_max_node_count" {
  description = "Maximum number of nodes"
  type        = number
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = ""
}

variable "acr_id" {
  description = "ID of the container registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
