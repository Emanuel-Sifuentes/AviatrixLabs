data "azurerm_virtual_network" "az-fw-vnet" {
  name = aviatrix_vpc.az-vpcs["az-transit-firenet-vnet"].name
  resource_group_name = azurerm_resource_group.az-rg.name
  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "azurerm_subnet" "az-fw-snet" {
    address_prefixes = ["${var.az-fw.snet-cidr}"]
    name = "${var.az-fw.snet-name}"
    resource_group_name = azurerm_resource_group.az-rg.name
    virtual_network_name = data.azurerm_virtual_network.az-fw-vnet.name

    depends_on = [
      aviatrix_vpc.az-vpcs
    ]
}

resource "azurerm_subnet" "az-fw-mgmt-snet" {
    address_prefixes = ["${var.az-fw.mgmt-cidr}"]
    name = "${var.az-fw.mgmt-name}"
    resource_group_name = azurerm_resource_group.az-rg.name
    virtual_network_name = data.azurerm_virtual_network.az-fw-vnet.name

    depends_on = [
      aviatrix_vpc.az-vpcs
    ]
}

resource "azurerm_route_table" "az-fw-rt" {
  location = var.az-region
  name = var.az-fw.rt_name
  resource_group_name = azurerm_resource_group.az-rg.name
  disable_bgp_route_propagation = true
  
  route {
      address_prefix = "0.0.0.0/0"
      name = "default-rt"
      next_hop_type = "Internet"
    }
}

resource "azurerm_subnet_route_table_association" "az-fw-rt-assc" {
  route_table_id = azurerm_route_table.az-fw-rt.id
  subnet_id = azurerm_subnet.az-fw-snet.id
}

data "azurerm_subnet" "az-fw-dummy-mgmt-snet" {
  name = aviatrix_vpc.az-vpcs["az-transit-firenet-vnet"].public_subnets[2].name
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = data.azurerm_virtual_network.az-fw-vnet.name
  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw
  ]
}

data "azurerm_subnet" "az-fw-dummy-wan-snet" {
  name = aviatrix_vpc.az-vpcs["az-transit-firenet-vnet"].public_subnets[0].name
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = data.azurerm_virtual_network.az-fw-vnet.name
  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw
  ]
}

data "azurerm_subnet" "az-fw-dummy-lan-snet" {
  name = var.az-fw.lan-name
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = data.azurerm_virtual_network.az-fw-vnet.name
  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw
  ]
}

resource "azurerm_public_ip" "az-fw-dummy-mgmt-pip" {
  name                = "az-fw-dummy-mgmt-pip"
  location            = var.az-region
  resource_group_name = azurerm_resource_group.az-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "az-fw-dummy-wan-pip" {
  name                = "az-fw-dummy-wan-pip"
  location            = var.az-region
  resource_group_name = azurerm_resource_group.az-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "az-fw-dummy-mgmt-nic" {
  location = var.az-region
  name = "az-fw-dummy-mgmt-nic"
  resource_group_name = azurerm_resource_group.az-rg.name

  ip_configuration {
    name = "az-fw-dummy-mgmt-nic"
    subnet_id = data.azurerm_subnet.az-fw-dummy-mgmt-snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az-fw-dummy-mgmt-pip.id
  }
  
}

resource "azurerm_network_interface" "az-fw-dummy-lan-nic" {
  location = var.az-region
  name = "az-fw-dummy-lan-nic"
  resource_group_name = azurerm_resource_group.az-rg.name
  enable_ip_forwarding = true

  ip_configuration {
    name = "az-fw-dummy-lan-nic"
    subnet_id = data.azurerm_subnet.az-fw-dummy-lan-snet.id
    private_ip_address_allocation = "Dynamic"
  }
  
}

resource "azurerm_network_interface" "az-fw-dummy-wan-nic" {
  location = var.az-region
  name = "az-fw-dummy-wan-nic"
  resource_group_name = azurerm_resource_group.az-rg.name

  ip_configuration {
    name = "az-fw-dummy-wan-nic"
    subnet_id = data.azurerm_subnet.az-fw-dummy-wan-snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az-fw-dummy-wan-pip.id
  }
  
}

resource "azurerm_virtual_machine" "az-dummy-vm" {
  name                  = var.az-fw.name
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-fw-dummy-mgmt-nic.id, azurerm_network_interface.az-fw-dummy-lan-nic.id, azurerm_network_interface.az-fw-dummy-wan-nic.id]
  primary_network_interface_id = azurerm_network_interface.az-fw-dummy-mgmt-nic.id
  vm_size               = var.az-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.az-fw.name}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "${var.az-fw.name}"
    admin_username = var.az-vm-user
    admin_password = var.az-vm-user-pwd
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  depends_on = [
    azurerm_network_interface.az-fw-dummy-mgmt-nic,
    azurerm_network_interface.az-fw-dummy-lan-nic,
    azurerm_network_interface.az-fw-dummy-wan-nic
  ]
}

resource "azurerm_public_ip" "az-fw-pip" {
  name                = "${var.az-fw.name}-pip"
  location            = var.az-region
  resource_group_name = azurerm_resource_group.az-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "az-fw-mgmt-pip" {
  name                = "${var.az-fw.name}-mgmt-pip"
  location            = var.az-region
  resource_group_name = azurerm_resource_group.az-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_log_analytics_workspace" "az-fw-law" {
  location = var.az-region
  name = var.az-fw.law_name
  resource_group_name = azurerm_resource_group.az-rg.name
  sku = "PerGB2018"
  retention_in_days = 30
}

resource "azurerm_firewall_policy" "az-fw-pol" {
  location = var.az-region
  name = var.az-fw.pol_name
  resource_group_name = azurerm_resource_group.az-rg.name
  sku = "Premium"
  
  dns {
    proxy_enabled = true
  }

  insights {
    enabled = true
    default_log_analytics_workspace_id = azurerm_log_analytics_workspace.az-fw-law.id
    retention_in_days = 30
  }

  intrusion_detection {
    mode = "Alert"
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "az-fw-pol-rcg" {
  firewall_policy_id = azurerm_firewall_policy.az-fw-pol.id
  name = "Allow-RFC1918-RCG"
  priority = 200

  network_rule_collection {
    name = "az-fw-network-rc"
    priority = 100
    action = "Allow"
    rule {
      name = "Allow-RFC1918"
      protocols = [ "Any" ]
      source_addresses = [ "10.0.0.0/8","172.16.0.0/12","192.168.0.0/16" ]
      destination_addresses = [ "*" ]
      destination_ports = [ "*" ]
    }
  }
  
  depends_on = [
    azurerm_firewall_policy.az-fw-pol
  ]
}

resource "azurerm_firewall" "az-fw" {
  location = var.az-region
  name = var.az-fw.name
  resource_group_name = azurerm_resource_group.az-rg.name
  sku_name = "AZFW_VNet"
  sku_tier = "Premium"
  firewall_policy_id = azurerm_firewall_policy.az-fw-pol.id

  management_ip_configuration {
    name = "az-fw-mgmt-ip-cfg"
    subnet_id = azurerm_subnet.az-fw-mgmt-snet.id
    public_ip_address_id = azurerm_public_ip.az-fw-mgmt-pip.id
  }
  
  ip_configuration {
    name = "az-fw-ip-cfg"
    subnet_id = azurerm_subnet.az-fw-snet.id
    public_ip_address_id = azurerm_public_ip.az-fw-pip.id
  }

  depends_on = [
    azurerm_firewall_policy.az-fw-pol,
    azurerm_firewall_policy_rule_collection_group.az-fw-pol-rcg
  ]
}

data "azurerm_monitor_diagnostic_categories" "az-fw-log-cat" {
    resource_id = azurerm_firewall.az-fw.id
    
}

/* resource "azurerm_monitor_diagnostic_setting" "az-fw-diags" {
    name = "az-fw-diag"
    target_resource_id = azurerm_firewall.az-fw.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.az-fw-law.id
    log_analytics_destination_type = "Dedicated"

    dynamic "log" {
        for_each = data.azurerm_monitor_diagnostic_categories.az-fw-log-cat.logs
        content {
            category = log.value
        }        
    }

    metric {
      category = "AllMetrics"
    }
    
    depends_on = [
      azurerm_firewall_policy.az-fw-pol,
      azurerm_firewall.az-fw,
      azurerm_log_analytics_workspace.az-fw-law
    ]
} */