provider "azurerm" {
  features {}
}

provider "postgresql" {
  host     = azurerm_postgresql_flexible_server.pg.fqdn
  port     = 5432
  database = azurerm_postgresql_flexible_server_database.app.name

  username = azurerm_postgresql_flexible_server.pg.administrator_login
  password = random_password.pg_admin.result

  sslmode   = "require"
  superuser = false
}

data "azurerm_client_config" "current" {}

locals {
  name_prefix = "${var.project}-${var.environment}-${var.location_short}"
  tags = {
    project     = var.project
    environment = var.environment
    owner       = var.owner_tag
  }

  pg_name = lower("pg-${local.name_prefix}")
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.tags
}

# Networking
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name_prefix}"
  address_space       = ["10.50.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-${local.name_prefix}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.50.1.0/24"]
}

# Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(local.name_prefix, "-", "")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = local.tags
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "kv-${local.name_prefix}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  rbac_authorization_enabled = true
  purge_protection_enabled   = false

  tags = local.tags
}

resource "azurerm_public_ip" "nat_outbound" {
  name                = "pip-nat-outbound-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "Standard"
  tags                = local.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat_pip" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_outbound.id
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "dns-${local.name_prefix}"

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    node_count           = var.node_count
    vnet_subnet_id       = azurerm_subnet.aks.id
    orchestrator_version = var.kubernetes_version
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  network_profile {
    load_balancer_sku   = "standard"
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
    outbound_type       = "userAssignedNATGateway"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  tags = local.tags

  depends_on = [
    azurerm_subnet_nat_gateway_association.aks
  ]
}

# Centralized logging destination
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-${local.name_prefix}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku               = "PerGB2018"
  retention_in_days = 30
  tags              = local.tags
}

# Static IP for Traefik Ingress Controller
resource "azurerm_public_ip" "traefik" {
  name                = "pip-traefik-${local.name_prefix}"
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

  domain_name_label   = "traefik-${var.project}-${var.environment}"

  tags                = local.tags
}

# Allow AKS nodes to pull images from ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

resource "azurerm_role_assignment" "kv_admin_me" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user_csi" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "random_password" "pg_admin" {
  length  = 24
  special = true
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "pg" {
  name                = local.pg_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  version    = "16"
  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768

  administrator_login = "hikuadmin"

  administrator_password = random_password.pg_admin.result

  public_network_access_enabled = true

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = local.tags
}

# Database for the application
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = "hikudb"
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# Enable required PostgreSQL extensions
resource "azurerm_postgresql_flexible_server_configuration" "extensions" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.pg.id
  value     = "UUID-OSSP,POSTGIS,PG_TRGM"
}

# Allow Azure services to access the PostgreSQL server
# resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
#   name             = "allow-azure"
#   server_id        = azurerm_postgresql_flexible_server.pg.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_aks_outbound" {
  name             = "allow-aks-outbound"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = azurerm_public_ip.nat_outbound.ip_address
  end_ip_address   = azurerm_public_ip.nat_outbound.ip_address
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_terraform_runner" {
  name             = "allow-terraform-runner"
  server_id        = azurerm_postgresql_flexible_server.pg.id
  start_ip_address = var.terraform_runner_ip
  end_ip_address   = var.terraform_runner_ip
}

# Store the admin credentials in Key Vault
resource "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  value        = random_password.pg_admin.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin_me]
}

# Store the admin username in Key Vault
resource "azurerm_key_vault_secret" "pg_admin_user" {
  name         = "pg-admin-user"
  value        = "hikuadmin"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin_me]
}

# Store the PostgreSQL host in Key Vault
resource "azurerm_key_vault_secret" "pg_host" {
  name         = "pg-host"
  value        = azurerm_postgresql_flexible_server.pg.fqdn
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_role_assignment.kv_admin_me]
}

# # # We set up the credentials for each microservice # # #
resource "random_password" "svc_db_password" {
  for_each = var.services
  length   = 24
  special  = true
}

resource "azurerm_key_vault_secret" "svc_db_user" {
  for_each     = var.services
  name         = "${each.key}-db-user"
  value        = each.value.db_user
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin_me]
}

resource "azurerm_key_vault_secret" "svc_db_password" {
  for_each     = var.services
  name         = "${each.key}-db-password"
  value        = random_password.svc_db_password[each.key].result
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin_me]
}

resource "azurerm_key_vault_secret" "svc_db_schema" {
  for_each     = var.services
  name         = "${each.key}-db-schema"
  value        = each.value.schema
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_role_assignment.kv_admin_me]
}
###########################################################

# # # Create per-service login roles # # #
resource "postgresql_role" "svc" {
  for_each = var.services

  name     = each.value.db_user
  login    = true
  password = random_password.svc_db_password[each.key].result

  depends_on = [
    azurerm_postgresql_flexible_server_database.app,
    azurerm_postgresql_flexible_server_firewall_rule.allow_aks_outbound,
    # azurerm_postgresql_flexible_server_firewall_rule.allow_azure,
    azurerm_postgresql_flexible_server_firewall_rule.allow_terraform_runner,
  ]
}

# Create per-service schema, owned by that role
resource "postgresql_schema" "svc" {
  for_each = var.services

  name     = each.value.schema
  owner    = postgresql_role.svc[each.key].name
  database = azurerm_postgresql_flexible_server_database.app.name
}

# Allow service role to use + create objects in its schema
resource "postgresql_grant" "schema_usage_create" {
  for_each = var.services

  database    = azurerm_postgresql_flexible_server_database.app.name
  role        = postgresql_role.svc[each.key].name
  schema      = postgresql_schema.svc[each.key].name
  object_type = "schema"
  privileges  = ["USAGE", "CREATE"]
}

# Default privileges for future tables
resource "postgresql_default_privileges" "tables" {
  for_each = var.services

  database    = azurerm_postgresql_flexible_server_database.app.name
  schema      = postgresql_schema.svc[each.key].name
  owner       = postgresql_role.svc[each.key].name
  role        = postgresql_role.svc[each.key].name
  object_type = "table"
  privileges  = ["SELECT", "INSERT", "UPDATE", "DELETE"]
}

# Default privileges for future sequences
resource "postgresql_default_privileges" "sequences" {
  for_each = var.services

  database    = azurerm_postgresql_flexible_server_database.app.name
  schema      = postgresql_schema.svc[each.key].name
  owner       = postgresql_role.svc[each.key].name
  role        = postgresql_role.svc[each.key].name
  object_type = "sequence"
  privileges  = ["USAGE", "SELECT", "UPDATE"]
}
##########################################

# # # KeyCloak # # #
resource "random_password" "keycloak_db_password" {
  length  = 32
  special = true
}

resource "postgresql_role" "keycloak" {
  name     = "keycloak_user"
  login    = true
  password = random_password.keycloak_db_password.result
}

resource "postgresql_database" "keycloak" {
  name              = "keycloak"
  owner             = postgresql_role.keycloak.name
  encoding          = "UTF8"
  lc_collate        = "en_US.utf8"
  lc_ctype          = "en_US.utf8"
  connection_limit  = -1
  allow_connections = true
}

resource "random_password" "keycloak_admin_password" {
  length  = 24
  special = true
}

resource "azurerm_key_vault_secret" "keycloak_db_username" {
  name         = "keycloak-db-username"
  value        = postgresql_role.keycloak.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "keycloak_db_password" {
  name         = "keycloak-db-password"
  value        = random_password.keycloak_db_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "keycloak_admin_username" {
  name         = "keycloak-admin-username"
  value        = "admin"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "keycloak_admin_password" {
  name         = "keycloak-admin-password"
  value        = random_password.keycloak_admin_password.result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "keycloak_db_name" {
  name         = "keycloak-db-name"
  value        = postgresql_database.keycloak.name
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "keycloak_db_host" {
  name         = "keycloak-db-host"
  value        = azurerm_postgresql_flexible_server.pg.fqdn
  key_vault_id = azurerm_key_vault.kv.id
}
####################