resource "azurerm_resource_group" "az-rg" {
  location = var.az-region
  name = var.az-rg-name
}

resource "aviatrix_vpc" "az-vpcs" {
  for_each = {for vpc in var.az-vpc-list : vpc.vpc_name => vpc }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = each.value.account_type
  name = each.value.vpc_name
  aviatrix_firenet_vpc = each.value.firenet_enabled
  resource_group = azurerm_resource_group.az-rg.name
  region = var.az-region
  cidr = "10.10.${each.value.octet}.0/23"

  depends_on = [
    azurerm_resource_group.az-rg
  ]
}

resource "aviatrix_transit_gateway" "az-firenet-gw" {
    account_name = aviatrix_account.az_account.account_name
    cloud_type = aviatrix_account.az_account.cloud_type
    gw_name = split("-vnet","${aviatrix_vpc.az-vpcs["az-eu2-transit-firenet-vnet"].name}")[0]
    gw_size = var.az-gw-size
    subnet = aviatrix_vpc.az-vpcs["az-eu2-transit-firenet-vnet"].public_subnets[2].cidr
    //ha_subnet = aviatrix_vpc.az-vpcs["az-eu2-transit-firenet-vnet"].public_subnets[3].cidr
    //ha_gw_size = var.az-gw-size
    vpc_id = aviatrix_vpc.az-vpcs["az-eu2-transit-firenet-vnet"].vpc_id
    vpc_reg = var.az-region
    connected_transit = true
    enable_transit_firenet = true
}

resource "aviatrix_spoke_gateway" "az-spoke1-gw" {
  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  gw_name = split("-vnet","${aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].name}")[0]
  gw_size = var.az-gw-size
  subnet = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].public_subnets[0].cidr
  vpc_id = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].vpc_id
  vpc_reg = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].region
  single_az_ha = false
  //ha_subnet = aviatrix_vpc.az-vpcs["az-eu2-spoke1-vnet"].public_subnets[1].cidr
  //ha_gw_size = var.az-gw-size
  manage_transit_gateway_attachment = false

  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "aviatrix_spoke_gateway" "aks-spoke-gw" {
  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  gw_name = "${var.aks-name}-gw"
  gw_size = var.az-gw-size
  subnet = azurerm_subnet.az-avtx-gw-snets[0].address_prefixes[0]
  vpc_id = "${azurerm_virtual_network.az-aks-vnet.name}:${azurerm_virtual_network.az-aks-vnet.resource_group_name}:${azurerm_virtual_network.az-aks-vnet.guid}"
  vpc_reg = var.az-region
  single_az_ha = false
  manage_transit_gateway_attachment = false

  depends_on = [
    azurerm_virtual_network.az-aks-vnet
  ]
  
}

resource "aviatrix_spoke_transit_attachment" "az-aks-transit-attach" {
  spoke_gw_name = aviatrix_spoke_gateway.aks-spoke-gw.gw_name
  transit_gw_name = aviatrix_transit_gateway.az-firenet-gw.gw_name
   depends_on = [
    aviatrix_transit_gateway.az-firenet-gw,
    aviatrix_spoke_gateway.aks-spoke-gw,
    azurerm_subnet_route_table_association.az-aks-rt-assc
  ]
} 

resource "aviatrix_spoke_transit_attachment" "az-spoke1-transit-attach" {
  spoke_gw_name = aviatrix_spoke_gateway.az-spoke1-gw.gw_name
  transit_gw_name = aviatrix_transit_gateway.az-firenet-gw.gw_name
  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw,
    aviatrix_spoke_gateway.az-spoke1-gw
  ]
} 

resource "aviatrix_gateway" "az-fqdn-egress-gw" {
  account_name = aviatrix_account.az_account.account_name
  cloud_type = 8
  gw_name = "${var.aks-name}-egress-gw"
  gw_size = var.az-gw-size
  subnet = azurerm_subnet.az-avtx-egress-gw-snets[0].address_prefixes[0]
  vpc_id = "${azurerm_virtual_network.az-aks-vnet.name}:${azurerm_virtual_network.az-aks-vnet.resource_group_name}:${azurerm_virtual_network.az-aks-vnet.guid}"
  vpc_reg = var.az-region
  single_az_ha = true
  single_ip_snat = true
  
  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "aviatrix_fqdn" "az-fqdn-egress-fqdn" {
  fqdn_tag = "${var.aks-name}-egress-fqdn-filter"
  fqdn_enabled = true
  fqdn_mode = "black"
  manage_domain_names = false
  
  gw_filter_tag_list {
    gw_name = aviatrix_gateway.az-fqdn-egress-gw.gw_name
  }

  depends_on = [
    aviatrix_gateway.az-fqdn-egress-gw
  ]

}

resource "aviatrix_firenet" "az-transit-firenet-cfg" {
    vpc_id = aviatrix_vpc.az-vpcs["az-eu2-transit-firenet-vnet"].vpc_id
    inspection_enabled = true
    egress_enabled = false
    manage_firewall_instance_association = false

       depends_on = [
        aviatrix_vpc.az-vpcs,
        aviatrix_transit_gateway.az-firenet-gw
    ] 
} 