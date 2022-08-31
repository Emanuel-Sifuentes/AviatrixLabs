output "az-jumpbox-public-ip" {
    value = azurerm_public_ip.az-jumpbox-vm-pip.ip_address
}

output "az-spoke1-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[0].private_ip_address
}

output "az-spoke2-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[1].private_ip_address
}
output "az-spoke3-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[2].private_ip_address
}

output "az-spoke4-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[3].private_ip_address
}
