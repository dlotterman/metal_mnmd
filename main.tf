# define provider version and Metal Token
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    equinix = {
      source  = "equinix/equinix"
      version = "~> 1.14"
    }
  }
  provider_meta "equinix" {
    module_name = "metal-mnmd"
  }
}

provider "equinix" {
  auth_token = var.metal_auth_token
}


resource "equinix_metal_vlan" "d_node_vlans" {
  for_each    = var.d_node_vlans
  description = "object_private d_node_vlans"
  metro       = var.metro
  project_id  = var.metal_project_id
  vxlan       = each.value
}

module "equinix_metal_nodes" {
  source           = "./modules/d_nodes/"
  project_id       = var.metal_project_id
  node_count       = var.d_node_count
  plan             = var.d_node_plan
  metro            = var.metro
  operating_system = var.operating_system
  metal_vlan       = [for v in equinix_metal_vlan.d_node_vlans : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.d_node_vlans]
  metal_node_tags = var.d_node_tags
}

resource "equinix_metal_vrf" "object_private_vrf" {
  description = "object_private VRF"
  name        = "object_private_vrf"
  metro       = var.metro
  project_id  = var.metal_project_id
  local_asn   = var.object_private_asn
  ip_ranges   = var.object_private_ip_ranges
}

resource "equinix_metal_gateway" "object_private_d_node_gw" {
  for_each          = var.d_node_vlans
  project_id        = var.metal_project_id
  vlan_id           = equinix_metal_vlan.d_node_vlans[each.value].id
  ip_reservation_id = equinix_metal_reserved_ip_block.object_private_d_node_ip.id
}

resource "equinix_metal_reserved_ip_block" "object_private_d_node_ip" {
  description = "Reserved gateway IP block (192.168.100.0/24) taken from one of the ranges in the VRF's pool of address space ip_ranges. "
  project_id  = var.metal_project_id
  metro       = var.metro
  type        = "vrf"
  vrf_id      = equinix_metal_vrf.object_private_vrf.id
  cidr        = 24
  network     = var.object_private_d_node_subnet
}

#########
module "c_nodes" {
  source           = "./modules/c_nodes/"
  project_id       = var.metal_project_id
  node_count       = var.c_node_count
  plan             = var.c_node_plan
  metro            = var.metro
  operating_system = var.operating_system
  metal_vlan       = [for v in equinix_metal_vlan.c_node_vlans : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.c_node_vlans]
  metal_node_tags = var.c_node_tags
}

resource "equinix_metal_vlan" "c_node_vlans" {
  for_each    = var.c_node_vlans
  description = "object_private c_node_vlans"
  metro       = var.metro
  project_id  = var.metal_project_id
  vxlan       = each.value
}


resource "equinix_metal_reserved_ip_block" "object_private_c_node_ip" {
  description = "object_private c_node ips"
  project_id  = var.metal_project_id
  metro       = var.metro
  type        = "vrf"
  vrf_id      = equinix_metal_vrf.object_private_vrf.id
  cidr        = 24
  network     = var.object_private_c_node_subnet
}

resource "equinix_metal_gateway" "object_private_c_node_gw" {
  for_each          = var.c_node_vlans
  project_id        = var.metal_project_id
  vlan_id           = equinix_metal_vlan.c_node_vlans[each.value].id
  ip_reservation_id = equinix_metal_reserved_ip_block.object_private_c_node_ip.id
}

#### z_nodes

module "z_nodes" {
  source           = "./modules/z_nodes/"
  project_id       = var.metal_project_id
  node_count       = var.z_node_count
  plan             = var.z_node_plan
  metro            = var.metro
  operating_system = var.operating_system
  metal_vlan       = [for v in equinix_metal_vlan.z_node_vlans : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.z_node_vlans]
  metal_node_tags = var.z_node_tags
}

resource "equinix_metal_vlan" "z_node_vlans" {
  for_each    = var.z_node_vlans
  description = "z_node_vlans"
  metro       = var.metro
  project_id  = var.metal_project_id
  vxlan       = each.value
}

resource "equinix_metal_reserved_ip_block" "object_private_z_node_ip" {
  description = "z_node ips"
  project_id  = var.metal_project_id
  metro       = var.metro
  type        = "vrf"
  vrf_id      = equinix_metal_vrf.object_private_vrf.id
  cidr        = 24
  network     = var.object_private_z_node_subnet
}

resource "equinix_metal_gateway" "object_private_z_node_gw" {
  for_each    = var.z_node_vlans
  project_id        = var.metal_project_id
  vlan_id           = equinix_metal_vlan.z_node_vlans[each.value].id
  ip_reservation_id = equinix_metal_reserved_ip_block.object_private_z_node_ip.id
}

#### l_nodes

module "l_nodes" {
  source           = "./modules/l_nodes/"
  project_id       = var.metal_project_id
  node_count       = var.l_node_count
  plan             = var.l_node_plan
  metro            = var.metro
  operating_system = var.operating_system
  metal_vlan       = [for v in equinix_metal_vlan.l_node_vlans : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.l_node_vlans]
  metal_node_tags = var.l_node_tags
}

resource "equinix_metal_vlan" "l_node_vlans" {
  for_each    = var.l_node_vlans
  description = "object_private l_node_vlans"
  metro       = var.metro
  project_id  = var.metal_project_id
  vxlan       = each.value
}

resource "equinix_metal_reserved_ip_block" "object_private_l_node_ip" {
  description = "l_node ips"
  project_id  = var.metal_project_id
  metro       = var.metro
  type        = "vrf"
  vrf_id      = equinix_metal_vrf.object_private_vrf.id
  cidr        = 24
  network     = var.object_private_l_node_subnet
}

resource "equinix_metal_gateway" "object_private_l_node_gw" {
  for_each    = var.l_node_vlans
  project_id        = var.metal_project_id
  vlan_id           = equinix_metal_vlan.l_node_vlans[each.value].id
  ip_reservation_id = equinix_metal_reserved_ip_block.object_private_l_node_ip.id
}
