#--------------------------------------------------------------------------------
# ACR
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "acr" {
  name     = local.acr_rg
  location = local.location
}

resource "azurerm_container_registry" "acr" {
  name                = local.acr_name # "${var.prefix}acr" # var.acr_name
  resource_group_name = azurerm_resource_group.acr.name
  location            = local.location # local.location # var.location
  sku                 = "Standard"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

#--------------------------------------------------------------------------------
# Storage Account
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "storage" {
  name     = local.storage_rg
  location = local.location
}

resource "azurerm_subnet" "storage" {
  name                 = "storage-subnet"
  resource_group_name  = local.aks_rg # azurerm_resource_group.aks.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.0.0/29"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false
}

resource "azurerm_storage_account" "storage" {
  name                      = local.storage_name
  resource_group_name       = azurerm_resource_group.storage.name
  location                  = local.location
  account_tier              = "Standard"     # "Premium"
  account_kind              = "StorageV2"    # "BlobStorage" "BlockBlobStorage" "FileStorage" "Storage"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  access_tier               = "Hot" # "Cool"
  allow_blob_public_access  = false

  network_rules {
    default_action = "Deny" # "Allow"
    ip_rules       = [data.http.machine_ip.body]
    bypass = ["Logging", "Metrics", "AzureServices"] # None
  }

  blob_properties {
    # cors_rule {}
    delete_retention_policy {
      days = 1 # between 1 and 365 days. Defaults to 7
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "container" {
  name                  = local.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private" # "blob" "container"
}

resource "azurerm_storage_blob" "blob" {
  name                   = "sample-file.sh"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Block"
  source                 = "terraform.sh"
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net" # "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.storage.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage-dns-vnet-link" {
  name                  = "storagednsvnetlink"
  resource_group_name   = azurerm_resource_group.storage.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "storage" {
  name                = "storage-private-endpoint"
  location            = local.location # var.location
  resource_group_name = azurerm_resource_group.storage.name
  subnet_id           = azurerm_subnet.storage.id

  private_dns_zone_group {
    name                 = "storprdnszonegroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }

  private_service_connection {
    name                           = "storage-private-service-connection"
    private_connection_resource_id = azurerm_storage_account.storage.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
}

#--------------------------------------------------------------------------------
# Key Vault
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
  resource_group_name  = local.aks_rg # azurerm_resource_group.aks.name
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

# TODO: Craete another Identity for Key Vault
resource "azurerm_role_assignment" "role_keyvault_reader" {
  role_definition_name = "Reader"
  principal_id         = data.azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                = azurerm_key_vault.keyvault.id

  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_rg_operator" {
  role_definition_name = "Managed Identity Operator"
  principal_id         = data.azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${data.azurerm_kubernetes_cluster.aks.node_resource_group}"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_vm_contributor" {
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${data.azurerm_kubernetes_cluster.aks.node_resource_group}"
  skip_service_principal_aad_check = true
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

#--------------------------------------------------------------------------------##
# Azure Identities
#--------------------------------------------------------------------------------##

resource "azurerm_user_assigned_identity" "storage" {
  name                = local.identity_name
  resource_group_name = data.azurerm_kubernetes_cluster.aks.node_resource_group
  location            = local.location
}
// az role assignment create \
//     --role "Managed Identity Operator" \
//     --assignee $CLUSTER_MSI_CLIENT_ID \
//     --scope $IDENTITY_RESOURCE_ID
resource "azurerm_role_assignment" "storage-mio" {
  scope                            = azurerm_user_assigned_identity.storage.id
  role_definition_name             = "Managed Identity Operator"
  principal_id                     = azurerm_user_assigned_identity.storage.principal_id
  skip_service_principal_aad_check = true
}
// az role assignment create \
//     --role "Storage Blob Data Contributor" \
//     --assignee $IDENTITY_CLIENT_ID \
//     --scope "$STORAGE_ACCOUNT_RESOURCE_ID/blobServices/default/containers/$CONTAINER"
// if you want the managed identity to access your entire Storage Account, 
// you can ignore /blobServices/default/containers/$CONTAINER
resource "azurerm_role_assignment" "storage-sbdc" {
  scope                            = azurerm_storage_account.storage.id # azurerm_user_assigned_identity.storage.id
  role_definition_name             = "Storage Blob Data Contributor"
  principal_id                     = azurerm_user_assigned_identity.storage.principal_id
  skip_service_principal_aad_check = true
}

#--------------------------------------------------------------------------------##
# Install tools in Bastion VM
#--------------------------------------------------------------------------------##
// resource "azurerm_virtual_machine_extension" "extension" {
//   name                 = "k8s-tools"
//   virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
//   publisher            = "Microsoft.Azure.Extensions"
//   type                 = "CustomScript"
//   type_handler_version = "2.0"

//   settings = <<SETTINGS
//     {
//         "commandToExecute": "hostname"
//     }
// SETTINGS
// }

# # Install Azure CLI
# Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
#
# # Install chocolately
# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#
# # Install Kubernetes CLI
# choco install kubernetes-cli
#
# # Install Helm CLI
# choco install kubernetes-helm