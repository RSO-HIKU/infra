output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "key_vault_name" {
  value = azurerm_key_vault.kv.name
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.aks.oidc_issuer_url
}

output "traefik_public_ip" {
  description = "Static public IP for Traefik ingress"
  value       = azurerm_public_ip.traefik.ip_address
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

# # # PostgreSQL outputs # # #
output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.pg.fqdn
}

output "postgres_db_name" {
  value = azurerm_postgresql_flexible_server_database.app.name
}

output "postgres_admin_user" {
  value = "hikuadmin"
}

output "postgres_admin_password" {
  value     = random_password.pg_admin.result
  sensitive = true
}
##############################

# # # Outputs for SecretProviderClass # # #
output "aks_kv_csi_client_id" {
  value = azurerm_kubernetes_cluster.aks.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}
###########################################