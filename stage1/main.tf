#--------------------------------------------------------------------------------
# Global resources
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "aks" {
  name     = local.aks_rg   # "${var.prefix}-aks-rg"
  location = local.location # local.location # var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name # "${var.prefix}-vnet"
  location            = local.location  # local.location # var.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.0.0.0/8"] # ["10.1.0.0/16"]
}

#--------------------------------------------------------------------------------
# AKS
#--------------------------------------------------------------------------------

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.aks.name
  address_prefixes     = ["10.1.0.0/16"] # ["10.1.0.0/22"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = true # false
}


resource "azurerm_kubernetes_cluster" "aks" {
  name                    = local.aks_name
  location                = local.location # local.location # var.location
  resource_group_name     = azurerm_resource_group.aks.name
  dns_prefix              = local.dns_prefix
  kubernetes_version      = local.kubernetes_version
  private_cluster_enabled = true
  sku_tier                = "Free" # Paid # Uptime SLA
  node_resource_group     = local.aks_nodes_rg

  default_node_pool {
    name                  = "system"
    node_count            = local.aks_default_node_count
    vm_size               = local.aks_vm_size
    type                  = "VirtualMachineScaleSets"
    availability_zones    = [1, 2, 3]
    enable_auto_scaling   = false
    min_count             = null
    max_count             = null
    enable_node_public_ip = false
    max_pods              = 110
    orchestrator_version  = local.kubernetes_version
    vnet_subnet_id        = azurerm_subnet.aks.id
  }

  network_profile {
    network_plugin    = "azure" # "kubenet"
    load_balancer_sku = "standard"
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled = false
    }
  }

  auto_scaler_profile {
    balance_similar_node_groups      = false
    max_graceful_termination_sec     = 600
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_delete    = "10s"
    scale_down_delay_after_failure   = "3m"
    scan_interval                    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
  }

  tags = {
    Environment = "Development"
  }
}

#--------------------------------------------------------------------------------
# ACR
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "acr" {
  name     = local.acr_rg   # "${var.prefix}-acr-rg"
  location = local.location # local.location # var.location
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
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  # principal_id                     = data.azurerm_user_assigned_identity.identity.principal_id
  skip_service_principal_aad_check = true
}

#--------------------------------------------------------------------------------
# BASTION
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "bastion" {
  name     = local.bastion_rg # "${var.prefix}-bastion-rg"
  location = "westeurope"
}

resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.0.0/27"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastionip"
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.bastion.location
  resource_group_name = azurerm_resource_group.bastion.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

#--------------------------------------------------------------------------------
# VM for BASTION
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "vm" {
  name     = local.vm_rg    # "${var.prefix}-vm-rg"
  location = local.location # local.location # var.location
}

resource "azurerm_subnet" "vm" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.3.0.0/29"]
}

resource "azurerm_network_interface" "vm" {
  name                = "vm-nic"
  location            = azurerm_resource_group.vm.location
  resource_group_name = azurerm_resource_group.vm.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "windows10-vm"
  resource_group_name = azurerm_resource_group.vm.name
  location            = azurerm_resource_group.vm.location
  size                = local.vm_size
  admin_username      = local.vm_admin_username
  admin_password      = local.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h1-pro-g2"
    version   = "latest"
  }
}

#--------------------------------------------------------------------------------
# Storage Account
#--------------------------------------------------------------------------------

resource "azurerm_resource_group" "storage" {
  name     = local.storage_rg
  location = local.location   # local.location # var.location
}

resource "azurerm_subnet" "storage" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.0.0/29"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = false
}

resource "azurerm_storage_account" "storage" {
  name                      = local.storage_name
  resource_group_name       = azurerm_resource_group.storage.name
  location                  = local.location # local.location # var.location
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
  virtual_network_id    = azurerm_virtual_network.vnet.id
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
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.aks.name
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
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                            = azurerm_key_vault.keyvault.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_rg_operator" {
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role_vm_contributor" {
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id
  scope                            = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourcegroups/${azurerm_kubernetes_cluster.aks.node_resource_group}"
  skip_service_principal_aad_check = true
}

resource "azurerm_key_vault_access_policy" "keyvault_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_kubernetes_cluster.aks.kubelet_identity.0.object_id

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
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "keyvault-private-endpoint"
  location            = local.location # var.location
  resource_group_name = azurerm_resource_group.keyvault.name
  subnet_id           = azurerm_subnet.aks.id

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
  name                = local.identity_name # "${var.prefix}-identity" # var.identity_name
  resource_group_name = azurerm_kubernetes_cluster.aks.node_resource_group
  location            = local.location # var.location
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
  scope                            = azurerm_user_assigned_identity.storage.id
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