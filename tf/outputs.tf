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

// output "keyvault_secrets" {
//   value = values(azurerm_key_vault_secret.secret-login).*.value
// }

// output "kube_config" {
//   value = azurerm_kubernetes_cluster.aks.kube_config_raw
// }

// output "client_key" {
//   value = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
// }

// output "client_certificate" {
//   value = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
// }

// output "cluster_ca_certificate" {
//   value = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
// }

// output "host" {
//   value = azurerm_kubernetes_cluster.aks.kube_config.0.host
// }