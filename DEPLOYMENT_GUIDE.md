# Complete Deployment Guide

This guide walks you through deploying the entire production-grade Azure SQL + AKS infrastructure from scratch.

**Estimated Time:** 25-30 minutes
**Difficulty:** Intermediate
**Cost:** ~$510/month

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step-by-Step Deployment](#step-by-step-deployment)
3. [Verification](#verification)
4. [High Availability Testing](#high-availability-testing)
5. [Troubleshooting](#troubleshooting)
6. [Cleanup](#cleanup)

---

## Prerequisites

### Required Tools

Ensure you have the following tools installed and configured:

```bash
# Verify Azure CLI
az --version
# Required: Azure CLI 2.50.0 or higher

# Verify Terraform
terraform --version
# Required: Terraform 1.5.0 or higher

# Verify Docker
docker --version
# Required: Docker 20.10.0 or higher

# Verify kubectl
kubectl version --client
# Required: kubectl 1.27.0 or higher
```

### Installation Instructions

**macOS:**
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install required tools
brew install azure-cli terraform docker kubectl
```

**Linux (Ubuntu/Debian):**
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Docker
sudo apt install docker.io

# kubectl
sudo snap install kubectl --classic
```

**Windows (PowerShell):**
```powershell
# Install using Chocolatey
choco install azure-cli terraform docker-desktop kubernetes-cli
```

### Azure Subscription Setup

```bash
# Login to Azure
az login

# List available subscriptions
az account list --output table

# Set your subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify active subscription
az account show --output table
```

### Get Your Public IP Address

```bash
# Get your public IP (required for SQL firewall)
curl -4 ifconfig.me

# Save this IP - you'll need it for terraform.tfvars
```

---

## Step-by-Step Deployment

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone <repository-url>
cd azure-sql-aks-unified

# Check the directory structure
ls -la
```

### Step 2: Configure Terraform Variables

Edit the `terraform.tfvars` file with your configuration:

```bash
# Open the file
nano terraform.tfvars
```

**Update the following line with your IP address:**
```hcl
my_ip_address = "YOUR_PUBLIC_IP"  # Replace with your actual IP from Step 1
```

**Optional: Customize other variables**
```hcl
# Project configuration
project_name = "quoteapp"
environment  = "learning"
location     = "eastus2"

# SQL Database
sql_admin_username = "sqladmin"
sql_database_sku   = "S1"  # Options: Basic, S1, S2, P1, P2

# AKS Cluster
aks_node_size      = "Standard_D2s_v5"
aks_min_node_count = 2
aks_max_node_count = 5

# Application Gateway
waf_enabled = true
waf_mode    = "Prevention"  # Options: Detection, Prevention
```

Save and exit (Ctrl+O, Enter, Ctrl+X in nano).

### Step 3: Deploy Infrastructure with Terraform

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Validate the configuration
terraform validate

# See what will be created (34 resources)
terraform plan

# Deploy the infrastructure (takes ~15-20 minutes)
terraform apply -auto-approve
```

**What Gets Created:**

| Resource Type | Count | Description |
|--------------|-------|-------------|
| Resource Group | 1 | Container for all resources |
| Virtual Network | 1 | Network isolation |
| Subnets | 3 | AKS, App Gateway, Private Endpoints |
| Network Security Groups | 2 | Traffic filtering |
| SQL Server | 1 | Database server |
| SQL Database | 1 | Application database |
| AKS Cluster | 1 | Kubernetes cluster |
| Node Pools | 1 | 2-5 nodes across 3 zones |
| Container Registry | 1 | Docker image storage |
| Application Gateway | 1 | Layer 7 load balancer with WAF |
| Public IPs | 2 | For App Gateway and LoadBalancer |
| Log Analytics | 1 | Monitoring workspace |
| RBAC Assignments | Multiple | Role-based access control |

**Total: 34 resources**

### Step 4: Export Terraform Outputs

After deployment completes, export the outputs for easy access:

```bash
# Export all important values
export ACR_NAME=$(terraform output -raw acr_name)
export ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)
export AKS_NAME=$(terraform output -raw aks_name)
export RESOURCE_GROUP=$(terraform output -raw resource_group_name)
export SQL_SERVER=$(terraform output -raw sql_server_fqdn)
export SQL_USERNAME=$(terraform output -raw sql_admin_username)
export SQL_PASSWORD=$(terraform output -raw sql_admin_password)
export SQL_DATABASE=$(terraform output -raw sql_database_name)
export APPGW_IP=$(terraform output -raw app_gateway_public_ip)

# Verify exports
echo "Resource Group: $RESOURCE_GROUP"
echo "ACR Name: $ACR_NAME"
echo "AKS Cluster: $AKS_NAME"
echo "SQL Server: $SQL_SERVER"
echo "App Gateway IP: $APPGW_IP"
```

### Step 5: Build and Push Docker Image

```bash
# Navigate to the application directory
cd application/quote-app

# Login to Azure Container Registry
az acr login --name $ACR_NAME

# Build the Docker image with ODBC Driver 18
docker build -t $ACR_LOGIN_SERVER/quote-app:v2 .

# Push to ACR
docker push $ACR_LOGIN_SERVER/quote-app:v2

# Verify the image was pushed
az acr repository show --name $ACR_NAME --repository quote-app

# List all tags
az acr repository show-tags --name $ACR_NAME --repository quote-app --output table

# Go back to root directory
cd ../..
```

**What the Dockerfile does:**
- Uses Python 3.11 slim base image
- Installs Microsoft ODBC Driver 18 for SQL Server
- Installs Python dependencies (Flask, pyodbc)
- Copies application code
- Exposes port 8080
- Runs Flask application

### Step 6: Configure Kubernetes Access

```bash
# Get AKS credentials (adds context to ~/.kube/config)
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Verify cluster access
kubectl cluster-info

# Check nodes (should see 2 nodes)
kubectl get nodes -o wide

# Verify nodes are in different availability zones
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone

# Expected output: Nodes in zones 1, 2, or 3
```

### Step 7: Update Deployment with Your ACR

```bash
# Update the deployment.yaml to use your ACR login server
sed -i.bak "s|acrquoteapplearning.*\.azurecr\.io|$ACR_LOGIN_SERVER|g" kubernetes/base/deployment.yaml

# Verify the change
grep "image:" kubernetes/base/deployment.yaml

# Expected: image: <your-acr-name>.azurecr.io/quote-app:v2
```

### Step 8: Initialize SQL Database

#### Option A: Using sqlcmd (Recommended)

```bash
# Navigate to database directory
cd application/database/

# Run initialization script
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -i init.sql

# Verify data was loaded (should show 50 quotes)
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -Q "SELECT COUNT(*) as quote_count FROM quotes"

# Test stored procedure
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -Q "EXEC GetRandomQuote"

# Go back to root directory
cd ../..
```

**Install sqlcmd if not available:**

```bash
# macOS
brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
brew install mssql-tools

# Linux
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y mssql-tools unixodbc-dev
```

#### Option B: Using Azure Portal

1. Open [Azure Portal](https://portal.azure.com)
2. Navigate to **SQL Databases** → Select your database
3. Click **Query editor (preview)** in the left menu
4. Login with:
   - **Login:** Value from `$SQL_USERNAME`
   - **Password:** Value from `$SQL_PASSWORD`
5. Open `application/database/init.sql` in a text editor
6. Copy the entire contents
7. Paste into Query editor
8. Click **Run**
9. Verify: `SELECT COUNT(*) FROM quotes` (should return 50)

**What the init.sql does:**
- Creates `quotes` table with proper schema
- Creates indexes for better performance
- Inserts 50 motivational quotes
- Creates `GetRandomQuote` stored procedure
- Creates `vw_QuoteStatistics` view

### Step 9: Create Kubernetes Secret

```bash
# Build the SQL connection string with ODBC Driver 18
SQL_CONNECTION_STRING="Driver={ODBC Driver 18 for SQL Server};Server=tcp:${SQL_SERVER},1433;Database=${SQL_DATABASE};UID=${SQL_USERNAME};PWD=${SQL_PASSWORD};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"

# Create the Kubernetes secret
kubectl create secret generic quote-app-secret \
  --from-literal=sql-connection-string="$SQL_CONNECTION_STRING" \
  --namespace=default

# Verify the secret was created
kubectl get secret quote-app-secret

# View secret details (base64 encoded)
kubectl get secret quote-app-secret -o yaml
```

**Important Notes:**
- The connection string MUST include `Driver={ODBC Driver 18 for SQL Server}`
- Use `yes`/`no` for boolean values (not `True`/`False`)
- The secret must be created BEFORE deploying pods

### Step 10: Deploy Application to Kubernetes

```bash
# Deploy the application (3 replicas with high availability)
kubectl apply -f kubernetes/base/deployment.yaml

# Deploy the LoadBalancer service
kubectl apply -f kubernetes/base/service.yaml

# Deploy Horizontal Pod Autoscaler (scales 3-10 pods)
kubectl apply -f kubernetes/autoscaling/hpa.yaml

# Deploy Pod Disruption Budget (min 2 pods available)
kubectl apply -f kubernetes/security/pod-disruption-budget.yaml
```

**Verify the deployment:**

```bash
# Check pods (should see 3 pods running)
kubectl get pods -o wide

# Check pod distribution across nodes
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,ZONE:.spec.nodeSelector

# Check service (wait for EXTERNAL-IP to be assigned)
kubectl get svc quote-app

# Check HPA (may show <unknown> initially)
kubectl get hpa

# Check Pod Disruption Budget
kubectl get pdb

# View application logs
kubectl logs -l app=quote-app --tail=50

# Follow logs in real-time
kubectl logs -l app=quote-app -f
```

**Wait for LoadBalancer IP (2-3 minutes):**

```bash
# Watch for EXTERNAL-IP to be assigned
kubectl get svc quote-app -w

# Once assigned, save it
export LB_IP=$(kubectl get svc quote-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "LoadBalancer IP: $LB_IP"
```

### Step 11: Test the Application

```bash
# Test health endpoint
curl http://$LB_IP/health

# Expected response:
# {"status": "healthy", "database": "connected", "service": "quote-app"}

# Test main application (get a random quote)
curl http://$LB_IP/

# Open in browser
echo "Open in browser: http://$LB_IP/"
```

**Expected in Browser:**
- Beautiful gradient purple/blue interface
- Random motivational quote
- Author attribution
- Category badge
- Statistics (50 quotes, X authors, X categories)
- "Get Another Quote" button

### Step 12: Configure Application Gateway Backend

```bash
# Update terraform.tfvars with the LoadBalancer IP
sed -i.bak "s|backend_address = \".*\"|backend_address = \"$LB_IP\"|g" terraform.tfvars

# Apply the Terraform change (updates only App Gateway backend)
terraform apply -auto-approve

# Test via Application Gateway
echo "Application Gateway URL: http://$APPGW_IP"

# Test health endpoint
curl http://$APPGW_IP/health

# Test application
curl http://$APPGW_IP/

# Open in browser
echo "Open in browser: http://$APPGW_IP/"
```

**Application Gateway Benefits:**
- WAF protection (blocks malicious requests)
- SSL/TLS termination capability
- URL-based routing
- Session affinity
- Health probes

---

## Verification

### Infrastructure Verification

```bash
# List all resources in the resource group
az resource list --resource-group $RESOURCE_GROUP --output table

# Check AKS cluster status
az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "provisioningState"
# Expected: "Succeeded"

# Check SQL Database status
az sql db show --resource-group $RESOURCE_GROUP --server ${SQL_SERVER%%.*} --name $SQL_DATABASE --query "status"
# Expected: "Online"

# Check Container Registry
az acr show --name $ACR_NAME --query "loginServer"

# Check Application Gateway health
az network application-gateway show-backend-health \
  --name appgw-quoteapp-learning \
  --resource-group $RESOURCE_GROUP \
  --output table
```

### Kubernetes Verification

```bash
# Check all Kubernetes resources
kubectl get all

# Verify deployments
kubectl get deployments
# Expected: quote-app with 3/3 replicas ready

# Verify pods are running and distributed
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase,IP:.status.podIP

# Verify nodes are in different zones
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone,STATUS:.status.conditions[3].type

# Check HPA metrics (may take a few minutes to populate)
kubectl get hpa quote-app-hpa
# Expected: 3 current replicas, scaling based on CPU/memory

# Check Pod Disruption Budget
kubectl get pdb quote-app-pdb
# Expected: min available = 2

# Verify secret exists
kubectl get secret quote-app-secret
```

### Application Verification

```bash
# Test LoadBalancer endpoint
echo "Testing LoadBalancer: http://$LB_IP"
curl -s http://$LB_IP/health | jq

# Test Application Gateway endpoint
echo "Testing App Gateway: http://$APPGW_IP"
curl -s http://$APPGW_IP/health | jq

# Get a random quote
curl -s http://$LB_IP/ | grep -o '<div class="quote-text">.*</div>' | head -1

# Check response time
time curl -s http://$LB_IP/ > /dev/null
```

### Database Verification

```bash
# Connect to database and run queries
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -Q "
SELECT
    (SELECT COUNT(*) FROM quotes) as TotalQuotes,
    (SELECT COUNT(DISTINCT author) FROM quotes) as TotalAuthors,
    (SELECT COUNT(DISTINCT category) FROM quotes) as TotalCategories;
"

# Test stored procedure
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -Q "EXEC GetRandomQuote"

# Check view
sqlcmd -S $SQL_SERVER -U $SQL_USERNAME -P "$SQL_PASSWORD" -d $SQL_DATABASE -Q "SELECT * FROM vw_QuoteStatistics"
```

---

## High Availability Testing

### Test 1: Multi-Zone Distribution Verification

```bash
# Verify nodes are in different availability zones
kubectl get nodes -o custom-columns=NAME:.metadata.name,ZONE:.metadata.labels.topology\\.kubernetes\\.io/zone

# Expected output: Nodes distributed across zones 1, 2, and 3
# Example:
# NAME                                ZONE
# aks-nodepool-12345678-vmss000000   eastus2-1
# aks-nodepool-12345678-vmss000001   eastus2-2

# Verify pods are on different nodes (anti-affinity)
kubectl get pods -o wide

# Expected: Each pod on a different node
```

**Why this matters:** If one datacenter (zone) fails, pods in other zones continue serving traffic.

### Test 2: Pod Auto-Scaling (HPA)

```bash
# Terminal 1: Generate load to trigger scaling
while true; do curl -s http://$LB_IP/ > /dev/null; done

# Terminal 2: Watch HPA scaling
watch kubectl get hpa

# Terminal 3: Watch pod count
watch kubectl get pods

# Expected behavior:
# - CPU/memory usage increases
# - HPA scales pods from 3 → 10
# - Scaling happens within 1-2 minutes
# - When load stops, scales down after 5 minutes

# Stop load generation (Ctrl+C in Terminal 1)
```

### Test 3: Node Scaling

```bash
# Check current node count
kubectl get nodes

# Check AKS cluster autoscaler status
az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "agentPoolProfiles[0].enableAutoScaling"

# Simulate heavy load to trigger node scaling
for i in {1..20}; do
  kubectl run load-test-$i --image=busybox --restart=Never --command -- sleep 3600
done

# Watch nodes scale up (2 → 5 nodes)
watch kubectl get nodes

# Clean up load test pods
kubectl delete pod -l run=load-test
```

### Test 4: Pod Failure Simulation

```bash
# Get a pod name
POD=$(kubectl get pods -l app=quote-app -o jsonpath='{.items[0].metadata.name}')

# Delete the pod
kubectl delete pod $POD

# Watch Kubernetes automatically recreate it
kubectl get pods -w

# Application should remain accessible
curl http://$LB_IP/health

# Expected: Pod recreated within 30 seconds, no downtime
```

### Test 5: Node Failure Simulation

```bash
# Get first node name
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# Cordon the node (prevent new pods)
kubectl cordon $NODE

# Drain the node (evict existing pods gracefully)
kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data

# Watch PDB in action (ensures min 2 pods stay available)
kubectl get pdb -w

# Watch pods reschedule to other nodes
kubectl get pods -o wide -w

# Application should remain accessible
curl http://$LB_IP/health

# Uncordon the node when done
kubectl uncordon $NODE
```

**Expected:** PDB prevents draining if it would violate the "min 2 available" rule.

### Test 6: Rolling Update (Zero Downtime)

```bash
# Update the deployment image to trigger rolling update
kubectl set image deployment/quote-app quote-app=$ACR_LOGIN_SERVER/quote-app:v2

# Watch rolling update (1 pod at a time, maxUnavailable=0)
kubectl rollout status deployment/quote-app

# Monitor in another terminal
watch kubectl get pods

# Continuously test application during update
while true; do
  curl -s http://$LB_IP/health && echo " - $(date)"
  sleep 1
done

# Expected: No failed requests during update
```

### Test 7: Database Connection Resilience

```bash
# Restart SQL Server (simulates brief outage)
az sql server restart --resource-group $RESOURCE_GROUP --server ${SQL_SERVER%%.*}

# Watch application recover automatically
kubectl logs -l app=quote-app -f

# Test application (may fail briefly, then recover)
for i in {1..10}; do
  curl -s http://$LB_IP/health
  sleep 2
done

# Expected: Automatic reconnection within 30 seconds
```

---

## Cleanup

### Step 1: Delete Kubernetes Resources (Optional)

```bash
# Delete application resources
kubectl delete -f kubernetes/security/pod-disruption-budget.yaml
kubectl delete -f kubernetes/autoscaling/hpa.yaml
kubectl delete -f kubernetes/base/service.yaml
kubectl delete -f kubernetes/base/deployment.yaml

# Delete secret
kubectl delete secret quote-app-secret

# Verify deletion
kubectl get all
```

### Step 2: Destroy Infrastructure

**Option A: Terraform Destroy (Recommended)**
```bash
# Destroy all infrastructure
terraform destroy -auto-approve

# Clean up Terraform state files
rm -rf .terraform
rm -rf .terraform.lock.hcl
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
```

**Option B: Delete Resource Group (Faster)**
```bash
# This deletes everything in the resource group at once
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Check deletion status
az group show --name $RESOURCE_GROUP

# Once deleted, you'll see: ResourceGroupNotFound
```

### Step 3: Cleanup Kubernetes Context

```bash
# Remove AKS context from kubeconfig
kubectl config delete-context $AKS_NAME

# List remaining contexts
kubectl config get-contexts

# Optional: Clean up entire kubeconfig
# rm ~/.kube/config
```

### Step 4: Cleanup Docker Images (Optional)

```bash
# Remove local Docker images
docker rmi $ACR_LOGIN_SERVER/quote-app:v1

# List remaining images
docker images
```

---

## Summary

### What You Deployed

✅ **Infrastructure (34 resources)**
- Resource Group
- Virtual Network with 3 subnets
- Network Security Groups
- Azure SQL Server + Database (S1)
- AKS Cluster (2-5 nodes, 3 zones)
- Container Registry
- Application Gateway with WAF v2
- Log Analytics Workspace

✅ **Application**
- Flask web application (Python 3.11)
- 3-10 pod replicas with auto-scaling
- LoadBalancer service
- Health probes and monitoring

✅ **High Availability**
- Multi-zone deployment
- Auto-scaling (pods and nodes)
- Pod anti-affinity
- Pod disruption budgets
- Zero-downtime updates

### Key Commands Reference

```bash
# Infrastructure
terraform apply -auto-approve
terraform destroy -auto-approve
terraform output

# Azure
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME
az acr login --name $ACR_NAME

# Kubernetes
kubectl get all
kubectl get pods -o wide
kubectl get hpa
kubectl logs -l app=quote-app -f
kubectl rollout restart deployment quote-app

# Testing
curl http://$LB_IP/health
curl http://$APPGW_IP/health
kubectl describe pod <pod-name>
```

---

**Need help?** Check the [main README](README.md) or open an issue on GitHub.
