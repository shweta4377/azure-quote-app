# ============================================================================
# OUTPUTS
# ============================================================================

# ----------------------------------------------------------------------------
# Resource Group
# ----------------------------------------------------------------------------
output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = module.resource_group.id
}

# ----------------------------------------------------------------------------
# Networking
# ----------------------------------------------------------------------------
output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

# ----------------------------------------------------------------------------
# Container Registry
# ----------------------------------------------------------------------------
output "acr_name" {
  description = "Name of the container registry"
  value       = module.acr.acr_name
}

output "acr_login_server" {
  description = "Login server for the container registry"
  value       = module.acr.acr_login_server
}

# ----------------------------------------------------------------------------
# SQL Database
# ----------------------------------------------------------------------------
output "sql_server_name" {
  description = "Name of the SQL Server"
  value       = module.database.sql_server_name
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = module.database.sql_server_fqdn
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = module.database.sql_database_name
}

output "sql_admin_username" {
  description = "SQL Server administrator username"
  value       = var.sql_admin_username
  sensitive   = true
}

output "sql_admin_password" {
  description = "SQL Server administrator password"
  value       = module.database.sql_admin_password
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Kubernetes (AKS)
# ----------------------------------------------------------------------------
output "aks_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.aks_name
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.aks_fqdn
}

output "aks_node_resource_group" {
  description = "Name of the AKS node resource group"
  value       = module.aks.aks_node_resource_group
}

# ----------------------------------------------------------------------------
# Key Vault (Commented out - using Kubernetes Secrets instead)
# ----------------------------------------------------------------------------
# output "key_vault_name" {
#   description = "Name of the Key Vault"
#   value       = module.key_vault.key_vault_name
# }
#
# output "key_vault_uri" {
#   description = "URI of the Key Vault"
#   value       = module.key_vault.key_vault_uri
# }
#
# output "workload_identity_client_id" {
#   description = "Client ID of the workload identity"
#   value       = module.key_vault.workload_identity_client_id
# }
#
# output "tenant_id" {
#   description = "Azure AD Tenant ID"
#   value       = module.key_vault.tenant_id
# }

# ----------------------------------------------------------------------------
# Application Gateway
# ----------------------------------------------------------------------------
output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = module.app_gateway.app_gateway_name
}

output "app_gateway_public_ip" {
  description = "Public IP address of the Application Gateway"
  value       = module.app_gateway.app_gateway_public_ip
}

output "app_gateway_fqdn" {
  description = "FQDN of the Application Gateway"
  value       = module.app_gateway.app_gateway_fqdn
}

# ----------------------------------------------------------------------------
# Connection Strings (Sensitive)
# ----------------------------------------------------------------------------
output "connection_strings" {
  description = "Database connection strings"
  value = {
    ado_net = "Server=tcp:${module.database.sql_server_fqdn},1433;Initial Catalog=${module.database.sql_database_name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${module.database.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    odbc    = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${module.database.sql_server_fqdn},1433;Database=${module.database.sql_database_name};Uid=${var.sql_admin_username};Pwd=${module.database.sql_admin_password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  }
  sensitive = true
}

# ----------------------------------------------------------------------------
# Next Steps
# ----------------------------------------------------------------------------
output "next_steps" {
  description = "Next steps for deployment"
  value = <<-EOT

  ========================================
  DEPLOYMENT SUCCESSFUL!
  ========================================

  Next Steps:

  1. Get AKS Credentials:
     az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.aks_name}

  2. Build and Push Docker Image:
     az acr login --name ${module.acr.acr_name}
     docker build -t ${module.acr.acr_login_server}/quote-app:v1 ../learning/step-by-step-deployment/step-05-quote-app/quote-app
     docker push ${module.acr.acr_login_server}/quote-app:v1

  3. Initialize SQL Database:
     sqlcmd -S ${module.database.sql_server_fqdn} -U ${var.sql_admin_username} -d ${module.database.sql_database_name} -i ../learning/step-by-step-deployment/step-03-sql-database/init.sql

  4. Create Kubernetes Secret:
     kubectl create secret generic quote-app-secret \
       --from-literal=sql-connection-string="Server=tcp:${module.database.sql_server_fqdn},1433;Initial Catalog=${module.database.sql_database_name};Persist Security Info=False;User ID=${var.sql_admin_username};Password=${module.database.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;" \
       --namespace=default

  5. Update deployment image with your ACR:
     sed -i.bak "s|acrquoteapplearning.*\\.azurecr\\.io|${module.acr.acr_login_server}|g" kubernetes/base/deployment.yaml

  6. Deploy Kubernetes Resources:
     kubectl apply -f kubernetes/base/deployment.yaml
     kubectl apply -f kubernetes/base/service.yaml
     kubectl apply -f kubernetes/autoscaling/hpa.yaml
     kubectl apply -f kubernetes/security/pod-disruption-budget.yaml

  7. Get Service IP:
     kubectl get svc quote-app

  8. Update Application Gateway backend_address in terraform.tfvars with the service IP and reapply:
     terraform apply

  ========================================
  EOT
  sensitive = true
}
