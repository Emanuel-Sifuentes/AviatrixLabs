output "az-jumpbox-public-ip" {
    value = azurerm_public_ip.az-jumpbox-vm-pip.ip_address
}

output "az-dev-vm-private-ip" {
    value = azurerm_network_interface.az-spoke1-priv-vm-nic.private_ip_address
}

output "az-fqdn-egress-gw-ip" {
  value = aviatrix_gateway.az-fqdn-egress-gw.eip
}

output "az-fw-ilb-ip" {
  value = azurerm_firewall.az-fw.ip_configuration[0].private_ip_address
}

output "az-mssql-fqdn" {
  value = azurerm_mssql_server.az-aks-sql.fully_qualified_domain_name
}

resource "local_file" "kubeconfig" {
  depends_on   = [azurerm_kubernetes_cluster.az-aks-cluster]
  filename     = "kubeconfig"
  content      = azurerm_kubernetes_cluster.az-aks-cluster.kube_config_raw
}