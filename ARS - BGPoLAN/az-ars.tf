resource "azurerm_virtual_network" "az-ars-vnet" {
    address_space = [ var.az-ars-vnet.cidr ]
    location = var.az-region
    name = var.az-ars-vnet.name
    resource_group_name = azurerm_resource_group.az-rg.name
    
}

resource "azurerm_subnet" "az-ars-snet" {
    address_prefixes = [ var.az-ars-vnet.gw_snet_cidr ]
    name = "RouteServerSubnet"
    resource_group_name = azurerm_resource_group.az-rg.name
    virtual_network_name = azurerm_virtual_network.az-ars-vnet.name
    
}

resource "azurerm_subnet" "az-ars-nva-snet" {
    address_prefixes = [ var.az-ars-vnet.nva_snet_cidr ]
    name = "workload-snet"
    resource_group_name = azurerm_resource_group.az-rg.name
    virtual_network_name = azurerm_virtual_network.az-ars-vnet.name
    
}

resource "azurerm_public_ip" "az-ars-pip" {
    allocation_method = "Static"
    location = var.az-region
    name = "az-ars-pip"
    resource_group_name = azurerm_resource_group.az-rg.name
    sku = "Standard"    
}

resource "azurerm_route_server" "az-ars" {
    location = var.az-region
    name = split("-vnet","${var.az-ars-vnet.name}")[0]
    public_ip_address_id = azurerm_public_ip.az-ars-pip.id
    resource_group_name = azurerm_resource_group.az-rg.name
    sku = "Standard"
    subnet_id = azurerm_subnet.az-ars-snet.id
    branch_to_branch_traffic_enabled = true
    
}

resource "azurerm_virtual_network_peering" "ars-to-avtx-transit-peering" {
  name = "ars-to-avtx-transit"
  remote_virtual_network_id = "${aviatrix_vpc.az-vpcs["az-eu2-firenet-vnet"].azure_vnet_resource_id}"
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-ars-vnet.name
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  allow_gateway_transit = true

  depends_on = [
    azurerm_route_server.az-ars
  ]
}

resource "azurerm_route_server_bgp_connection" "ars-to-avtx-gw" {
  name = "avtx-gw"
  peer_asn = aviatrix_transit_gateway.az-firenet-gw.local_as_number
  peer_ip = aviatrix_transit_gateway.az-firenet-gw.bgp_lan_ip_list[0]
  route_server_id = azurerm_route_server.az-ars.id
  
}

resource "azurerm_route_server_bgp_connection" "ars-to-avtx-ha-gw" {
  name = "avtx-ha-gw"
  peer_asn = aviatrix_transit_gateway.az-firenet-gw.local_as_number
  peer_ip = aviatrix_transit_gateway.az-firenet-gw.ha_bgp_lan_ip_list[0]
  route_server_id = azurerm_route_server.az-ars.id
  
}

resource "azurerm_virtual_network" "az-ars-spoke1-vnet" {
  address_space = [ var.az-ars-spoke1-vnet.cidr ]
  location = var.az-region
  name = var.az-ars-spoke1-vnet.name
  resource_group_name = azurerm_resource_group.az-rg.name
  
}

resource "azurerm_subnet" "az-ars-spoke1-workload-snet" {
    address_prefixes = [ var.az-ars-spoke1-vnet.vm_snet_cidr ]
    name = "workload-snet"
    resource_group_name = azurerm_resource_group.az-rg.name
    virtual_network_name = azurerm_virtual_network.az-ars-spoke1-vnet.name
    
}

resource "azurerm_network_interface" "az-ars-spoke1-vm-nic" {
  location = var.az-region
  name = "az-ars-spoke1-vm-nic"
  resource_group_name = azurerm_resource_group.az-rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "az-ars-spoke1-vm-nic-ipcfg"
    subnet_id                     = azurerm_subnet.az-ars-spoke1-workload-snet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_virtual_machine" "az-ars-spoke1-vm" {
  name                  = "az-ars-spoke1-vm"
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-ars-spoke1-vm-nic.id]
  vm_size               = var.az-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-ars-spoke1-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "az-ars-spoke1-vm"
    admin_username = var.az-vm-user
    admin_password = var.az-vm-user-pwd
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = true
    storage_uri = azurerm_storage_account.az-avtxlabsa.primary_blob_endpoint
  }
}

resource "azurerm_virtual_network_peering" "spoke1-to-ars-peering" {
  name = "spoke1-to-ars-peering"
  remote_virtual_network_id = azurerm_virtual_network.az-ars-vnet.id
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-ars-spoke1-vnet.name
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  use_remote_gateways = true

  depends_on = [
    azurerm_route_server.az-ars,
    azurerm_virtual_network_peering.ars-to-spoke1-peering
  ]
}

resource "azurerm_virtual_network_peering" "ars-to-spoke1-peering" {
  name = "ars-to-spoke1-peering"
  remote_virtual_network_id = azurerm_virtual_network.az-ars-spoke1-vnet.id
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = azurerm_virtual_network.az-ars-vnet.name
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  allow_gateway_transit = true

  depends_on = [
    azurerm_route_server.az-ars
  ]
}


resource "azurerm_route_table" "az-ars-spoke1-rt" {
  location = var.az-region
  name = "workload-rt"
  resource_group_name = azurerm_resource_group.az-rg.name
  disable_bgp_route_propagation = true
  
  route {
      address_prefix = "0.0.0.0/0"
      name = "default-rt"
      next_hop_type = "VirtualAppliance"
      next_hop_in_ip_address = var.az-ars-nva-ilb-ip
    }
}

resource "azurerm_subnet_route_table_association" "az-ars-spoke1-rt-assc" {
  route_table_id = azurerm_route_table.az-ars-spoke1-rt.id
  subnet_id = azurerm_subnet.az-ars-spoke1-workload-snet.id

  depends_on = [
    azurerm_route_table.az-ars-spoke1-rt
  ]
}