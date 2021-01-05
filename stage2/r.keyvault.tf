#--------------------------------------------------------------------------------
# Key Vault (Private)
#--------------------------------------------------------------------------------

data "azurerm_client_config" "current" {
}

resource "azurerm_resource_group" "keyvault" {
  name     = local.keyvault_rg # "${var.prefix}-keyvault-rg"
  location = local.location    # var.location
}

resource "azurerm_subnet" "keyvault" {
  name                 = "keyvault-subnet"
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  resource_group_name  = local.aks_rg
  address_prefixes     = ["10.4.0.0/29"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false
}

resource "azurerm_key_vault" "keyvault" {
  name                        = local.keyvault_name # "${var.prefix}keyvault"
  location                    = local.location      # var.location
  resource_group_name         = azurerm_resource_group.keyvault.name
  enabled_for_disk_encryption = false
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "set",
      "get",
      "list",
      "delete",
    ]

    storage_permissions = [
      "get",
    ]
  }

  network_acls {
    default_action = "Deny"          # "Allow"
    bypass         = "AzureServices" # "None"
    ip_rules       = [data.http.machine_ip.body]
    # ip_rules       = var.allowed_ips # IP Addresses, or CIDR Blocks which should be able to access the Key Vault.
    # virtual_network_subnet_ids = [] # Subnet ID's which should be able to access this Key Vault
  }
}

resource "azurerm_key_vault_secret" "secret-login" {
  name         = "DatabaseLogin"
  value        = local.db_admin_login
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "secret-password" {
  name         = "DatabasePassword"
  value        = local.db_admin_password
  key_vault_id = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_access_policy" "keyvault_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id

  secret_permissions = [
    "get",
  ]

  depends_on = [
    azurerm_key_vault.keyvault
  ]
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net" # "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.keyvault.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name                  = "dnszonelink"
  resource_group_name   = azurerm_resource_group.keyvault.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "keyvault-private-endpoint"
  location            = local.location
  resource_group_name = azurerm_resource_group.keyvault.name
  subnet_id           = azurerm_subnet.keyvault.id

  private_dns_zone_group {
    name                 = "privatednszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  private_service_connection {
    name                           = "example-private-service-connection"
    private_connection_resource_id = azurerm_key_vault.keyvault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }
}

resource "azurerm_user_assigned_identity" "keyvault" {
  name                = local.keyvault_identity_name
  resource_group_name = local.aks_nodes_rg # data.azurerm_kubernetes_cluster.aks.node_resource_group
  location            = local.location
}

resource "azurerm_role_assignment" "keyvault_reader" {
  principal_id                     = azurerm_user_assigned_identity.keyvault.principal_id
  role_definition_name             = "Reader"
  scope                            = azurerm_key_vault.keyvault.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_rg_operator" {
  principal_id                     = azurerm_user_assigned_identity.keyvault.principal_id
  role_definition_name             = "Managed Identity Operator"
  scope                            = azurerm_user_assigned_identity.storage.id # "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${local.aks_nodes_rg}"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_contributor" {
  principal_id                     = azurerm_user_assigned_identity.keyvault.principal_id
  role_definition_name             = "Virtual Machine Contributor"
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${local.aks_nodes_rg}"
  skip_service_principal_aad_check = true
}
