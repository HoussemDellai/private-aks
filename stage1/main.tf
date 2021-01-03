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
  address_space       = ["10.0.0.0/8"]
}

#--------------------------------------------------------------------------------
# AKS
#--------------------------------------------------------------------------------

resource "azurerm_subnet" "aks" {
  name                 = "aks-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.aks.name
  address_prefixes     = ["10.1.0.0/16"]

  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = true
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