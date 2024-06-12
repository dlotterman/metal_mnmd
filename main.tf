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

# allocate a metal's metro vlans for the project

resource "equinix_metal_vlan" "metro_vlan" {
  count       = var.vlan_count
  description = "Metal's metro VLAN"
  metro       = var.metro
  project_id  = var.metal_project_id
}

# deploy Metal server(s)

module "equinix_metal_nodes" {
  source           = "./modules/metalnodes/"
  project_id       = var.metal_project_id
  node_count       = var.server_count
  plan             = var.plan
  metro            = var.metro
  operating_system = var.operating_system
  tags			   = var.metal_nodes_tags
  metal_vlan       = [for v in equinix_metal_vlan.metro_vlan : { vxlan = v.vxlan, id = v.id }]
  depends_on       = [equinix_metal_vlan.metro_vlan]
}


