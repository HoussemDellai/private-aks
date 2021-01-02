output "id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "versions" {
  value = data.azurerm_kubernetes_service_versions.current.versions
}

output "latest_version" {
  value = data.azurerm_kubernetes_service_versions.current.latest_version
}

output "keyvault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.keyvault.id
}

output "keyvault_url" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.keyvault.vault_uri
}