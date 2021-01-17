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
  resource_group_name = local.vm_rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = local.vm_name
  resource_group_name = local.vm_rg
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

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm.id]
  }
}

resource "azurerm_user_assigned_identity" "vm" {
  name                = local.vm_identity_name
  resource_group_name = local.vm_rg
  location            = local.location
}

resource "azurerm_role_assignment" "vm-contributor" {
  principal_id         = azurerm_user_assigned_identity.vm.principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.subscription.id

  skip_service_principal_aad_check = true
}

data "azurerm_subscription" "subscription" {
}

resource "azurerm_virtual_machine_extension" "install-tools" {

  name                 = "install-tools"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  settings             = <<SETTINGS
    {
        "fileUris": ["https://raw.githubusercontent.com/HoussemDellai/private-aks/main/stage1/build-agent.ps1"],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file build-agent.ps1"
    }
  SETTINGS
}