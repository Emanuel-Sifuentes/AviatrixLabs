resource "azurerm_resource_group" "az-aks-rg" {
    location = var.az-region
    name = var.aks-rg-name
}

resource "azurerm_virtual_network" "az-aks-vnet" {
    address_space = [ "${var.aks-vnet-cidr}" ]
    location = var.az-region
    name = var.aks-vnet-name
    resource_group_name = azurerm_resource_group.az-aks-rg.name

    depends_on = [
      azurerm_resource_group.az-aks-rg
    ]
}

resource "azurerm_subnet" "az-aks-snet" {
    address_prefixes = [ "${local.aks-snet-cidrs[0]}" ]
    name = "${var.aks-name}-snet"
    resource_group_name = azurerm_resource_group.az-aks-rg.name
    virtual_network_name = azurerm_virtual_network.az-aks-vnet.name

    depends_on = [
      azurerm_virtual_network.az-aks-vnet
    ]
}

resource "azurerm_route_table" "az-aks-snet-rt" {
  location = var.az-region
  name = "${var.aks-name}-rt"
  resource_group_name = azurerm_resource_group.az-aks-rg.name
  disable_bgp_route_propagation = true
  
  route {
      address_prefix = "0.0.0.0/0"
      name = "default-rt"
      next_hop_type = "None"
    }
}

resource "azurerm_subnet" "az-aks-agic-snet" {
    address_prefixes = [ "${local.aks-snet-cidrs[5]}" ]
    name = "${var.aks-name}-agic-snet"
    resource_group_name = azurerm_resource_group.az-aks-rg.name
    virtual_network_name = azurerm_virtual_network.az-aks-vnet.name

    depends_on = [
      azurerm_virtual_network.az-aks-vnet
    ]
}

resource "azurerm_route_table" "az-aks-agic-snet-rt" {
  location = var.az-region
  name = "${var.aks-name}-agic-rt"
  resource_group_name = azurerm_resource_group.az-aks-rg.name
  disable_bgp_route_propagation = false
  
  route {
      address_prefix = "0.0.0.0/0"
      name = "default-rt"
      next_hop_type = "Internet"
    }
}

resource "azurerm_subnet_route_table_association" "az-aks-agic-rt-assc" {
  route_table_id = azurerm_route_table.az-aks-agic-snet-rt.id
  subnet_id = azurerm_subnet.az-aks-agic-snet.id

  depends_on = [
    azurerm_route_table.az-aks-agic-snet-rt
  ]
}

resource "azurerm_subnet_route_table_association" "az-aks-rt-assc" {
  route_table_id = azurerm_route_table.az-aks-snet-rt.id
  subnet_id = azurerm_subnet.az-aks-snet.id

  depends_on = [
    azurerm_route_table.az-aks-snet-rt
  ]
}

resource "azurerm_subnet" "az-avtx-gw-snets" {
    count = 2
    address_prefixes = [ "${local.aks-snet-cidrs[count.index+1]}" ]
    name = "avx-gw-snet-${count.index+1}"
    resource_group_name = azurerm_resource_group.az-aks-rg.name
    virtual_network_name = azurerm_virtual_network.az-aks-vnet.name
    
    depends_on = [
      azurerm_virtual_network.az-aks-vnet
    ]
}

resource "azurerm_subnet" "az-avtx-egress-gw-snets" {
    count = 2
    address_prefixes = [ "${local.aks-snet-cidrs[count.index+3]}" ]
    name = "avx-egress-gw-snet-${count.index+1}"
    resource_group_name = azurerm_resource_group.az-aks-rg.name
    virtual_network_name = azurerm_virtual_network.az-aks-vnet.name
    
}

resource "azurerm_kubernetes_cluster" "az-aks-cluster" {
  name                = var.aks-name
  location            = var.az-region
  resource_group_name = azurerm_resource_group.az-aks-rg.name
  dns_prefix          = var.aks-dns-prefix

  network_profile {
    network_plugin = "azure"
    network_mode = "transparent"
    outbound_type = "userDefinedRouting"
  }

  default_node_pool {
    name       = "akspool"
    node_count = "2"
    vm_size    = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.az-aks-snet.id
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_name = "${var.aks-name}-agic"
    subnet_id = azurerm_subnet.az-aks-agic-snet.id
  }

  depends_on = [
    aviatrix_spoke_transit_attachment.az-aks-transit-attach
  ] 

}

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
    subnet_id                     = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].public_subnets[2].subnet_id
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
  vm_size               = var.az-vm-size

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
    custom_data = "${file("user_init.sh")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      key_data = var.az-ssh-key-value
      path = "/home/${var.az-vm-user}/.ssh/authorized_keys"
    }
  }

  boot_diagnostics {
    enabled = true
    storage_uri = azurerm_storage_account.az-avtxlabsa.primary_blob_endpoint
  }
}

resource "azurerm_network_interface" "az-spoke1-priv-vm-nic" {
  name                 = "az-spoke1-priv-vm-nic"
  location             = var.az-region
  resource_group_name  = azurerm_resource_group.az-rg.name

  ip_configuration {
    name                          = "az-spoke1-priv-vm-nic-ipcfg"
    subnet_id                     = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].private_subnets[0].subnet_id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "azurerm_virtual_machine" "az-spoke1-priv-vm" {
  name                  = "az-spoke1-priv-vm"
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-spoke1-priv-vm-nic.id]
  vm_size               = var.az-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-spoke1-priv-vm-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "az-spoke1-priv-vm"
    admin_username = var.az-vm-user
    admin_password = var.az-vm-user-pwd
  }

  os_profile_linux_config {
    disable_password_authentication = false
    ssh_keys {
      key_data = var.az-ssh-key-value
      path = "/home/${var.az-vm-user}/.ssh/authorized_keys"
    }
  }

  boot_diagnostics {
    enabled = true
    storage_uri = azurerm_storage_account.az-avtxlabsa.primary_blob_endpoint
  }

  depends_on = [
    azurerm_resource_group.az-rg,
    azurerm_network_interface.az-spoke1-priv-vm-nic
  ]
}

resource "azurerm_mssql_server" "az-aks-sql" {
  location = var.az-region
  name = "${var.sql-name}-${random_string.az-avtxlabsa-random.id}"
  resource_group_name = azurerm_resource_group.az-aks-rg.name
  version = "12.0"
  administrator_login = var.sql-user
  administrator_login_password = var.sql-pwd
  
}

resource "azurerm_mssql_database" "az-aks-sql-db" {
  name = "${var.sql-name}-db"
  server_id = azurerm_mssql_server.az-aks-sql.id
  sku_name = "Basic"
}