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
  subnet_size = "26"
  num_of_subnet_pairs = "1"

  depends_on = [
    azurerm_resource_group.az-rg
  ]
}

resource "aviatrix_transit_gateway" "az-firenet-gw" {
    account_name = aviatrix_account.az_account.account_name
    cloud_type = 8
    gw_name = split("-vnet","${aviatrix_vpc.az-vpcs["az-eu2-firenet-vnet"].name}")[0]
    gw_size = var.az-transit-gw-size
    subnet = "10.10.${var.az-vpc-list[3].octet}.192/26"
    ha_subnet = "10.10.${var.az-vpc-list[3].octet+1}.192/26"
    ha_gw_size = var.az-transit-gw-size
    vpc_id = aviatrix_vpc.az-vpcs["az-eu2-firenet-vnet"].vpc_id
    vpc_reg = var.az-region
    connected_transit = true
    insane_mode = true
    enable_bgp_over_lan = true
    bgp_lan_interfaces_count = 2
    local_as_number = 65501

    depends_on = [
      aviatrix_vpc.az-vpcs
    ]
}

resource "aviatrix_spoke_gateway" "az-spoke-gws" {

  for_each = {for vpc in var.az-spoke-list : vpc.vpc_name => vpc }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = 8
  gw_name = split("-vnet","${each.value.vpc_name}")[0]
  gw_size = var.az-spoke-gw-size
  subnet = "10.10.${each.value.octet}.0/26"
  //subnet = azurerm_subnet.az-hpe-snet["${each.value.vpc_name}"].name
  vpc_id = aviatrix_vpc.az-vpcs["${each.value.vpc_name}"].vpc_id
  vpc_reg = aviatrix_vpc.az-vpcs["${each.value.vpc_name}"].region
  single_az_ha = false
  //ha_subnet = aviatrix_vpc.az-vpcs["az-eu2-qa-vnet"].public_subnets[1].cidr
  //ha_gw_size = var.az-gw-size
  single_ip_snat = true
  insane_mode = false

  depends_on = [
    aviatrix_vpc.az-vpcs
  ]
}

resource "aviatrix_spoke_transit_attachment" "az-spokes-transit-attach" {
  for_each = {for vpc in var.az-spoke-list : vpc.vpc_name => vpc }

  spoke_gw_name = aviatrix_spoke_gateway.az-spoke-gws["${each.value.vpc_name}"].gw_name
  transit_gw_name = aviatrix_transit_gateway.az-firenet-gw.gw_name
  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw,
    aviatrix_spoke_gateway.az-spoke-gws
  ]
}

resource "aviatrix_azure_spoke_native_peering" "az-jumpbox-native-attach" {
  spoke_account_name = aviatrix_account.az_account.account_name
  spoke_region = var.az-region
  spoke_vpc_id = aviatrix_vpc.az-vpcs["az-eu2-jumpbox-vnet"].vpc_id
  transit_gateway_name = aviatrix_transit_gateway.az-firenet-gw.gw_name

  depends_on = [
    aviatrix_transit_gateway.az-firenet-gw
  ]
} 

resource "azurerm_virtual_network_peering" "avtx-transit-to-ars-peering" {
  name = "avtx-transit-to-ars"
  remote_virtual_network_id = azurerm_virtual_network.az-ars-vnet.id
  resource_group_name = azurerm_resource_group.az-rg.name
  virtual_network_name = "${aviatrix_vpc.az-vpcs["az-eu2-firenet-vnet"].name}"
  allow_forwarded_traffic = true
  allow_virtual_network_access = true
  use_remote_gateways = true

  depends_on = [
    azurerm_route_server.az-ars
  ]
}

resource "aviatrix_transit_external_device_conn" "avtx-transit-to-ars-conn" {
  connection_name = "avtx-to-ars"
  connection_type = "bgp"
  tunnel_protocol = "LAN"
  gw_name = aviatrix_transit_gateway.az-firenet-gw.gw_name
  vpc_id = aviatrix_vpc.az-vpcs["az-eu2-firenet-vnet"].vpc_id
  remote_vpc_name = "${azurerm_virtual_network.az-ars-vnet.name}:${azurerm_virtual_network.az-ars-vnet.resource_group_name}:${var.az-sub-id}"
  bgp_local_as_num = aviatrix_transit_gateway.az-firenet-gw.local_as_number
  bgp_remote_as_num = azurerm_route_server.az-ars.virtual_router_asn
  backup_bgp_remote_as_num = azurerm_route_server.az-ars.virtual_router_asn
  enable_bgp_lan_activemesh = true
  ha_enabled = true
  remote_lan_ip = tolist(azurerm_route_server.az-ars.virtual_router_ips)[0]
  //local_lan_ip = aviatrix_transit_gateway.az-firenet-gw.bgp_lan_ip_list[0]
  backup_remote_lan_ip = tolist(azurerm_route_server.az-ars.virtual_router_ips)[1]
  //backup_local_lan_ip = aviatrix_transit_gateway.az-firenet-gw.ha_bgp_lan_ip_list[0]
  
}