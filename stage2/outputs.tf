output "keyvault_id" {
  value       = azurerm_key_vault.keyvault.id
}

output "keyvault_url" {
  value       = azurerm_key_vault.keyvault.vault_uri
}

output "storage_account_id" {
  value = azurerm_storage_account.storage.id
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.storage.primary_blob_endpoint
}

output "blob_url" {
  value = azurerm_storage_blob.blob.url
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_private_fqdn" {
  value = azurerm_kubernetes_cluster.aks.private_fqdn
}

output "aks_versions" {
  value = data.azurerm_kubernetes_service_versions.current.versions
}

output "aks_latest_version" {
  value = data.azurerm_kubernetes_service_versions.current.latest_version
}