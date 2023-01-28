resource "azurerm_public_ip" "az-ars-nva-pip" {
    count = 2
    allocation_method = "Static"
    location = var.az-region
    name = "az-ars-nva-pip-${count.index+1}"
    resource_group_name = azurerm_resource_group.az-rg.name
    sku = "Standard"
}

resource "azurerm_network_interface" "az-ars-nva-nic" {
  count = 2
  location = var.az-region
  name = "az-ars-nva-nic-${count.index+1}"
  resource_group_name = azurerm_resource_group.az-rg.name
  enable_accelerated_networking = true
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "az-ars-nva-nic-${count.index+1}-ipcfg"
    subnet_id                     = azurerm_subnet.az-ars-nva-snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.az-ars-nva-pip[count.index].id
  }
  
}

resource "azurerm_network_security_group" "az-ars-nva-nsg" {
    count = 2
    location = var.az-region
    name = "az-ars-nva-nsg-${count.index+1}"
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

    security_rule {
    name                       = "Allow-RFC-1918"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes = [ "10.0.0.0/8","172.16.0.0/12","192.168.0.0/16" ]
    destination_address_prefix = "*"
  }
    security_rule {
    name                       = "Allow-ip-forward"
    priority                   = 300
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefixes = [ "10.0.0.0/8","172.16.0.0/12","192.168.0.0/16" ]
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "az-ars-nva-nic-nsg-assc" {
    count = 2
    network_interface_id = azurerm_network_interface.az-ars-nva-nic[count.index].id
    network_security_group_id = azurerm_network_security_group.az-ars-nva-nsg[count.index].id
}

resource "azurerm_virtual_machine" "az-ars-nva" {
  count = 2
  name                  = "az-ars-nva-${count.index+1}"
  location              = var.az-region
  resource_group_name   = azurerm_resource_group.az-rg.name
  network_interface_ids = [azurerm_network_interface.az-ars-nva-nic[count.index].id]
  vm_size               = var.az-vm-size

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "az-ars-nva-${count.index}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_data_disks_on_termination = true
  delete_os_disk_on_termination = true

  os_profile {
    computer_name  = "az-ars-nva-${count.index}"
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

locals {
  ars-ip-1 = tolist(azurerm_route_server.az-ars.virtual_router_ips)[0]
  ars-ip-2 = tolist(azurerm_route_server.az-ars.virtual_router_ips)[1]
}

resource "azurerm_virtual_machine_extension" "az-ars-nva-bootstrap" {
    count = 2
    name                 = "nva${count.index+1}bootstrap"
    virtual_machine_id   = azurerm_virtual_machine.az-ars-nva[count.index].id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"


    settings = <<SETTINGS
    {
        "fileUris": [
        "https://raw.githubusercontent.com/Emanuel-Sifuentes/AviatrixLabs/main/ARS%20-%20BGPoLAN/quagga.sh"
        ],
        "commandToExecute": "./quagga.sh ${var.az-ars-nva-asn} ${azurerm_network_interface.az-ars-nva-nic[count.index].ip_configuration[0].private_ip_address} ${var.az-ars-nva-summarized-route} ${local.ars-ip-1} ${local.ars-ip-2} ${var.az-ars-nva-ilb-ip}"
    }
SETTINGS

}

resource "azurerm_virtual_machine_extension" "az-ars-nva-iptables" {
    count = 2
    name                 = "nva${count.index+1}iptables"
    virtual_machine_id   = azurerm_virtual_machine.az-ars-nva[count.index].id
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"


    settings = <<SETTINGS
    {
        "fileUris": [
        "https://raw.githubusercontent.com/Emanuel-Sifuentes/AviatrixLabs/main/ARS%20-%20BGPoLAN/iptables.sh"
        ],
        "commandToExecute": "./iptables.sh\"
    }
SETTINGS

    depends_on = [
      azurerm_virtual_machine_extension.az-ars-nva-bootstrap
    ]

}

resource "azurerm_lb" "az-ars-nva-ilb" {
    location = var.az-region
    name = "az-ars-nva"
    resource_group_name = azurerm_resource_group.az-rg.name
    sku = "Standard"

    frontend_ip_configuration {
      name = "az-ars-nva-ilb"
      subnet_id = azurerm_subnet.az-ars-nva-snet.id
      private_ip_address_allocation = "Static"
      private_ip_address = var.az-ars-nva-ilb-ip
      private_ip_address_version = "IPv4"
    }
    
}

resource "azurerm_lb_backend_address_pool" "az-ars-nva-be-pool" {
    loadbalancer_id = azurerm_lb.az-ars-nva-ilb.id
    name = "nva-be-pool"

}

resource "azurerm_lb_probe" "az-ars-nva-probe" {
    loadbalancer_id = azurerm_lb.az-ars-nva-ilb.id
    name = "nva-probe"
    port = 22
    protocol = "Tcp"
    
}

resource "azurerm_lb_rule" "az-ars-nva-rule" {
    backend_port = 0
    frontend_ip_configuration_name = azurerm_lb.az-ars-nva-ilb.frontend_ip_configuration[0].name
    frontend_port = 0
    loadbalancer_id = azurerm_lb.az-ars-nva-ilb.id
    name = "nva-rule"
    protocol = "All"
    probe_id = azurerm_lb_probe.az-ars-nva-probe.id
    backend_address_pool_ids = [ "${azurerm_lb_backend_address_pool.az-ars-nva-be-pool.id}" ]
    
}

resource "azurerm_network_interface_backend_address_pool_association" "az-ars-nva-nic-be-pool-assc" {
    count = 2
    backend_address_pool_id = azurerm_lb_backend_address_pool.az-ars-nva-be-pool.id
    ip_configuration_name = azurerm_network_interface.az-ars-nva-nic[count.index].ip_configuration[0].name
    network_interface_id = azurerm_network_interface.az-ars-nva-nic[count.index].id

}

resource "azurerm_route_server_bgp_connection" "az-ars-nva-bgp-peer" {
  count = 2
  name = "nva-to-ars-peer-${count.index+1}"
  peer_asn = var.az-ars-nva-asn
  peer_ip = azurerm_network_interface.az-ars-nva-nic[count.index].ip_configuration[0].private_ip_address
  route_server_id = azurerm_route_server.az-ars.id
  
}