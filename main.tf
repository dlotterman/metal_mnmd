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
    module_name = "equinix-metal-vrf"
  }
}

provider "equinix" {
  auth_token = var.metal_auth_token
}

import {
    for_each = var.m_node_vlans
	to = equinix_metal_vlan.metro_vlan[each.key]
	id = each.value.UUID
}

# allocate a metal's metro vlans for the project
resource "equinix_metal_vlan" "metro_vlan" {
  for_each    = var.m_node_vlans
  #for_each    = var.m_node_vlans
  description = "MinIO VLAN"
  metro       = var.metro
  project_id  = var.metal_project_id
  vxlan		  = each.value.VLAN
}

# deploy Metal server(s)

module "equinix_metal_nodes" {
  source           = "./modules/metalnodes/"
  project_id       = var.metal_project_id
  node_count       = var.server_count
  plan             = var.plan
  metro            = var.metro
  operating_system = var.operating_system
  metal_vlan       = [for v in equinix_metal_vlan.metro_vlan : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.metro_vlan]
}


