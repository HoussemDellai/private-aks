output "keyvault_id" {
  description = "Key Vault ID"
  value       = azurerm_key_vault.keyvault.id
}

output "keyvault_url" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.keyvault.vault_uri
}