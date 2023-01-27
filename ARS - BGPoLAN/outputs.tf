output "az-jumpbox-public-ip" {
    value = azurerm_public_ip.az-jumpbox-vm-pip.ip_address
}

output "az-spoke1-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[0].private_ip_address
}

output "az-spoke2-vm-private-ip" {
    value = azurerm_network_interface.az-vm-nics[1].private_ip_address
}

output "az-ars-spoke1-vm-private-ip" {
    value = azurerm_network_interface.az-ars-spoke1-vm-nic.private_ip_address
}

output "az-ars-private-ip-1" {
    value = tolist(azurerm_route_server.az-ars.virtual_router_ips)[0]
}

output "az-ars-private-ip-2" {
    value = tolist(azurerm_route_server.az-ars.virtual_router_ips)[1]
}

output "az-ars-nva1-pip" {
  value = azurerm_public_ip.az-ars-nva-pip[0].ip_address
}

output "az-ars-nva2-pip" {
  value = azurerm_public_ip.az-ars-nva-pip[1].ip_address
}

output "vm-user" {
  value = var.az-vm-user
}

output "vm-user-password" {
  value = var.az-vm-user-pwd
}