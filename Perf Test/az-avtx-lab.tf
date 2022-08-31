resource "azurerm_resource_group" "az-rg" {
  location = var.az-region
  name = var.az-rg-name
}

resource "aviatrix_vpc" "az-spoke-vnets" {
  for_each = {for vnet in var.az-spoke-list : vnet.vnet_name => vnet }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  name = each.value.vnet_name
  aviatrix_firenet_vpc = each.value.firenet_enabled
  resource_group = azurerm_resource_group.az-rg.name
  region = var.az-region
  cidr = each.value.cidr
}

resource "aviatrix_vpc" "az-transit-vnets" {
  for_each = {for vnet in var.az-transit-list : vnet.vnet_name => vnet }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  name = each.value.vnet_name
  aviatrix_firenet_vpc = each.value.firenet_enabled
  resource_group = azurerm_resource_group.az-rg.name
  region = var.az-region
  cidr = each.value.cidr
}

resource "aviatrix_transit_gateway" "az-firenet-gws" {
  for_each = {for transit-gw in var.az-transit-list : transit-gw.vnet_name => transit-gw }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  gw_name = split("-vnet","${each.value.vnet_name}")[0]
  gw_size = var.az-transit-gw-size
  subnet = replace("${each.value.cidr}","0.0/23","1.0/26")
  //ha_subnet = replace("${each.value.cidr}","0.0/23","1.64/26")
  //ha_gw_size = var.az-transit-gw-size
  vpc_id = aviatrix_vpc.az-transit-vnets["${each.value.vnet_name}"].vpc_id
  vpc_reg = var.az-region
  connected_transit = true
  insane_mode = true
  enable_transit_firenet = true
}

resource "aviatrix_spoke_gateway" "az-spoke-gws" {
  for_each = {for spoke-gw in var.az-spoke-list : spoke-gw.vnet_name => spoke-gw }

  account_name = aviatrix_account.az_account.account_name
  cloud_type = aviatrix_account.az_account.cloud_type
  gw_name = split("-vnet","${each.value.vnet_name}")[0]
  gw_size = var.az-spoke-gw-size
  subnet = replace("${each.value.cidr}","0.0/23","1.0/26")
  vpc_id = aviatrix_vpc.az-spoke-vnets["${each.value.vnet_name}"].vpc_id
  vpc_reg = aviatrix_vpc.az-spoke-vnets["${each.value.vnet_name}"].region
  single_az_ha = false
  //ha_subnet = replace("${each.value.cidr}","0.0/23","1.64/26")
  //ha_gw_size = var.az-spoke-gw-size
  manage_transit_gateway_attachment = false
  single_ip_snat = true
  insane_mode = true
}

resource "aviatrix_spoke_transit_attachment" "az-spokes-transit1-attach" {
  count = 2
  spoke_gw_name = aviatrix_spoke_gateway.az-spoke-gws["az-eu2-spoke${count.index+1}-vnet"].gw_name
  transit_gw_name = aviatrix_transit_gateway.az-firenet-gws["az-eu2-firenet1-vnet"].gw_name
} 

resource "aviatrix_spoke_transit_attachment" "az-spokes-transit2-attach" {
  count = 2
  spoke_gw_name = aviatrix_spoke_gateway.az-spoke-gws["az-eu2-spoke${count.index+3}-vnet"].gw_name
  transit_gw_name = aviatrix_transit_gateway.az-firenet-gws["az-eu2-firenet2-vnet"].gw_name
} 

resource "aviatrix_azure_spoke_native_peering" "az-jumpbox-native-attach" {
  spoke_account_name = aviatrix_account.az_account.account_name
  spoke_region = var.az-region
  spoke_vpc_id = aviatrix_vpc.az-spoke-vnets["az-eu2-jumpbox-vnet"].vpc_id
  transit_gateway_name = aviatrix_transit_gateway.az-firenet-gws["az-eu2-firenet1-vnet"].gw_name
}

resource "aviatrix_transit_gateway_peering" "az-transit-gw-peering" {
  transit_gateway_name1 = aviatrix_transit_gateway.az-firenet-gws["az-eu2-firenet1-vnet"].gw_name
  transit_gateway_name2 = aviatrix_transit_gateway.az-firenet-gws["az-eu2-firenet2-vnet"].gw_name
  enable_max_performance = true
}