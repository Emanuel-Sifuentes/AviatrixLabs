resource "random_string" "az-avtxlabsa-random" {
    length = 6
    special = false
    upper = false
    min_numeric = 2
    
}

resource "azurerm_storage_account" "az-avtxlabsa" {
    account_replication_type = "LRS"
    account_tier = "Standard"
    location = var.az-region
    name = "avtxlabsa${random_string.az-avtxlabsa-random.id}"
    resource_group_name = azurerm_resource_group.az-rg.name
}

resource "azurerm_public_ip" "az-jumpbox-vm-pip" {
    allocation_method = "Static"
    location = var.az-region
    name = "az-jumpbox-vm-pip"
    resource_group_name = azurerm_resource_group.az-rg.name
    sku = "Standard"    
}

resource "azurerm_network_interface" "az-jumpbox-vm-nic" {
  name                 = "az-jumpbox-vm-nic"
  location             = var.az-region
  resource_group_name  = azurerm_resource_group.az-rg.name

  ip_configuration {
    name                          = "az-jumpbox-vm-nic-ipcfg"
    subnet_id                     = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].public_subnets[1].subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az-jumpbox-vm-pip.id
  }

  depends_on = [
    aviatrix_vpc.az-vpcs,
    azurerm_public_ip.az-jumpbox-vm-pip
  ]
}

resource "azurerm_network_security_group" "az-jumpbox-vm-nsg" {
    location = var.az-region
    name = "az-jumpbox-vm-nsg"
    resource_group_name = azurerm_resource_group.az-rg.name

    security_rule {
    name                       = "Allow-home-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${data.http.get_ip.body}/32"
    destination_address_prefix = "*"
  }
    
}

resource "azurerm_network_interface_security_group_association" "az-jumpbox-vm-nsg-assc" {
    network_interface_id = azurerm_network_interface.az-jumpbox-vm-nic.id
    network_security_group_id = azurerm_network_security_group.az-jumpbox-vm-nsg.id

    depends_on = [
      azurerm_network_interface.az-jumpbox-vm-nic,
      azurerm_network_security_group.az-jumpbox-vm-nsg
    ]
}

resource "azurerm_virtual_machine" "az-jumpbox-vm" {
  name                  = "az-jumpbox-vm"
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-jumpbox-vm-nic.id]
  vm_size               = var.az-jumpbox-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-jumpbox-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "az-jumpbox-vm"
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

resource "azurerm_network_interface" "az-vm-nics" {
  count = 2
  location = var.az-region
  name = "az-spoke${count.index+1}-vm-nic"
  resource_group_name = azurerm_resource_group.az-rg.name
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "az-spoke${count.index+1}-vm-nic-ipcfg"
    subnet_id                     = aviatrix_vpc.az-vpcs["az-eu2-spoke${count.index+1}-vnet"].private_subnets[0].subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  
  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "azurerm_virtual_machine" "az-vms" {
  count = 2
  name                  = "az-spoke${count.index+1}-vm"
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-vm-nics[count.index].id]
  vm_size               = var.az-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-spoke${count.index+1}-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "az-spoke${count.index+1}-vm"
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

  depends_on = [
    azurerm_resource_group.az-rg,
    azurerm_network_interface.az-vm-nics,
    //aviatrix_spoke_transit_attachment.az-spokes-transit-attach
  ]
}