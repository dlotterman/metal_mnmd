variable "metal_auth_token" {
  type        = string
  description = "Your Equinix Metal API key (https://console.equinix.com/users/-/api-keys)"
  sensitive   = true
}

variable "metal_project_id" {
  type        = string
  description = "Your Equinix Metal project ID, where you want to deploy your nodes to"
}

variable "plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "c3.medium.x86"
}

variable "operating_system" {
  type        = string
  description = "OS you want to deploy"
  default     = "ubuntu_24_04"
}

variable "metro" {
  type        = string
  description = "Metal's Metro location you want to deploy your servers to"
  default     = "sv"
}

variable "d_node_vlans" {
  type    = set(string)
  default = [249]
}

variable "server_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 3
}

variable "metal_node_tags" {
  type    = list(string)
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.249","MMNMD_VLAN_249","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.248.0","MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private","MMNMD_ROUTE2_172.16.247.0"]
}

variable "metal_asn" {
  type        = number
  description = "Metal's local ASN"
  default     = 65414
}

variable "ip_ranges" {
  type        = list(any)
  description = "Your reserved IP ranges"
  default = ["172.16.0.0/12"]
}

variable "object_private_d_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.249.0"
}

#############

variable "c_node_tags" {
  type    = list(string)
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.248","MMNMD_VLAN_248","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.249.0","MMNMD_ADNS_172.16.249.2-172.16.249.3:249.private","MMNMD_ROUTE2_172.16.247.0"]
}

variable "object_private_c_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.248.0"
}
variable "c_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 3
}
variable "c_node_plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "m3.large.x86"
}

variable "c_node_vlans" {
  type    = set(string)
  default = [248]
}

#############

variable "z_node_tags" {
  type    = list(string)
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.247","MMNMD_VLAN_247","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.248.0","MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private","MMNMD_ROUTE2_172.16.249.0","MMNMD_ADNS2_172.16.249.2-172.16.249.3:249.private"]
}

variable "object_private_z_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.247.0"
}
variable "z_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 3
}
variable "z_node_vlans" {
  type    = set(string)
  default = [247]
}
variable "z_node_plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "c3.medium.x86"
}
