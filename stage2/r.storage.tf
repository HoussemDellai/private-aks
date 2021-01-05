#--------------------------------------------------------------------------------
# Storage Account (Private)
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
  name                = "privatelink.blob.core.windows.net"
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
  location            = local.location
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

#----------------------------------------------------------------------------------
# Azure Identities
#----------------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "storage" {
  name                = local.storage_identity_name
  resource_group_name =  local.aks_nodes_rg # data.azurerm_kubernetes_cluster.aks.node_resource_group
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
