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

// #--------------------------------------------------------------------------------
// # AKS
// #--------------------------------------------------------------------------------

// resource "azurerm_subnet" "aks" {
//   name                 = "aks-subnet"
//   virtual_network_name = azurerm_virtual_network.vnet.name
//   resource_group_name  = azurerm_resource_group.aks.name
//   address_prefixes     = ["10.1.0.0/16"]

//   enforce_private_link_endpoint_network_policies = true
//   enforce_private_link_service_network_policies  = true
// }

// resource "azurerm_kubernetes_cluster" "aks" {
//   name                    = local.aks_name
//   location                = local.location # local.location # var.location
//   resource_group_name     = azurerm_resource_group.aks.name
//   dns_prefix              = local.dns_prefix
//   kubernetes_version      = local.kubernetes_version
//   private_cluster_enabled = true
//   sku_tier                = "Free" # Paid # Uptime SLA
//   node_resource_group     = local.aks_nodes_rg

//   default_node_pool {
//     name                  = "system"
//     node_count            = local.aks_default_node_count
//     vm_size               = local.aks_vm_size
//     type                  = "VirtualMachineScaleSets"
//     availability_zones    = [1, 2, 3]
//     enable_auto_scaling   = false
//     min_count             = null
//     max_count             = null
//     enable_node_public_ip = false
//     max_pods              = 110
//     orchestrator_version  = local.kubernetes_version
//     vnet_subnet_id        = azurerm_subnet.aks.id
//   }

//   network_profile {
//     network_plugin    = "azure" # "kubenet"
//     load_balancer_sku = "standard"
//   }

//   identity {
//     type = "SystemAssigned"
//   }

//   role_based_access_control {
//     enabled = true
//   }

//   addon_profile {
//     aci_connector_linux {
//       enabled = false
//     }

//     azure_policy {
//       enabled = false
//     }

//     http_application_routing {
//       enabled = false
//     }

//     kube_dashboard {
//       enabled = false
//     }

//     oms_agent {
//       enabled = false
//     }
//   }

//   auto_scaler_profile {
//     balance_similar_node_groups      = false
//     max_graceful_termination_sec     = 600
//     scale_down_delay_after_add       = "10m"
//     scale_down_delay_after_delete    = "10s"
//     scale_down_delay_after_failure   = "3m"
//     scan_interval                    = "10s"
//     scale_down_unneeded              = "10m"
//     scale_down_unready               = "20m"
//     scale_down_utilization_threshold = "0.5"
//   }
// }