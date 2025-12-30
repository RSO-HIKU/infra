output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
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