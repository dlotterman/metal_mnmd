
# define provider version and Metal Token
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    equinix = {
      source = "equinix/equinix"
      version = "~> 1.14"
    }
  }
  provider_meta "equinix" {
    module_name = "metal-mnmd/metalnodes"
  }
}

variable "project_id" {}
variable "node_count" {}
variable "plan" {}
variable "metro" {}
variable "operating_system" {}
variable "metal_vlan" {}
variable "metal_nodes_tags" {}

# create metal nodes
resource "equinix_metal_device" "metal_nodes" {
  count            = var.node_count
  hostname         = format("m-%d", count.index + 2)
  plan             = var.plan
  metro            = var.metro
  operating_system = var.operating_system
  billing_cycle    = "hourly"
  project_id       = var.project_id
  tags			   = var.metal_nodes_tags
  user_data        = data.cloudinit_config.config[count.index].rendered
  depends_on       = [var.metal_vlan]
  behavior {allow_changes=["user_data"]}
}

data "cloudinit_config" "config" {
  count         = var.node_count
  gzip          = false # not supported on Equinix Metal
  base64_encode = false # not supported on Equinix Metal

  part {
    content_type = "text/cloud-config"
    content      = file("${path.module}/ubuntu_minio.yaml")
  }
}

## put metal nodes in layer2 bonded mode and attach metro vlan to the nodes
resource "equinix_metal_port" "port" {
  count = var.node_count
  port_id  = [for p in equinix_metal_device.metal_nodes[count.index].ports : p.id if p.name == "bond0"][0]
  layer2   = false
  bonded   = true
  vlan_ids = var.metal_vlan.*.id
  depends_on = [equinix_metal_device.metal_nodes]
}

