variable "metal_auth_token" {
  type        = string
  description = "Your Equinix Metal API key (https://console.equinix.com/users/-/api-keys)"
  sensitive   = true
}

variable "metal_project_id" {
  type        = string
  description = "Your Equinix Metal project ID, where you want to deploy your nodes to"
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

variable "object_private_asn" {
  type        = number
  description = "Metal's local ASN"
  default     = 65414
}

variable "object_private_ip_ranges" {
  type        = list(any)
  description = "object_private allowed ranges"
  default = ["172.16.0.0/12"]
}

############# d_nodes

variable "d_node_plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "c3.medium.x86"
}

variable "d_node_vlans" {
  type    = set(string)
  default = [249]
}

variable "d_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 0
}

variable "d_node_tags" {
  type    = list(string)
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.249","MMNMD_VLAN_249","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.248.0","MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private","MMNMD_ROUTE2_172.16.247.0","MMNMD_ROUTE3_172.16.246.0","MMNMD_ADNS3_172.16.246.2-172.16.246.3:246.private"]
}

variable "object_private_d_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.249.0"
}

############# c_nodes

variable "c_node_tags" {
  type    = list(string)
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.248","MMNMD_VLAN_248","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.249.0","MMNMD_ADNS_172.16.249.2-172.16.249.3:249.private","MMNMD_ROUTE2_172.16.247.0","MMNMD_ROUTE3_172.16.246.0","MMNMD_ADNS3_172.16.246.2-172.16.246.3:246.private"]
}

variable "object_private_c_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.248.0"
}
variable "c_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 4
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
  default = ["MMNMD_BRANCH_dlott_initial3","MMNMD_SUBNET_172.16.247","MMNMD_VLAN_247","MMNMD_GROUP1_2-4","MMNMD_ROUTE1_172.16.248.0","MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private","MMNMD_ROUTE2_172.16.249.0","MMNMD_ADNS2_172.16.249.2-172.16.249.3:249.private","MMNMD_ROUTE3_172.16.246.0","MMNMD_ADNS3_172.16.246.2-172.16.246.3:246.private"]
}

variable "object_private_z_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.247.0"
}
variable "z_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 0
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

#############

variable "l_node_tags" {
  type    = list(string)
  default = ["MMNMD_SUBNET_172.16.246","MMNMD_VLAN_246","MMNMD_GROUP1_2-5","MMNMD_ROUTE1_172.16.248.0","MMNMD_ADNS1_172.16.248.2-172.16.248.3:248.private","MMNMD_ROUTE2_172.16.249.0","MMNMD_ADNS2_172.16.249.2-172.16.249.3:249.private","MMNMD_ROUTE3_172.16.247.0","MMNMD_ADNS3_172.16.247.2-172.16.247.3:247.private","MNMD_LBT_GROUP1_2-4:c-:249.private:object.249.private:2249"]
}

variable "object_private_l_node_subnet" {
  type        = string
  description = "OS you want to deploy"
  default     = "172.16.246.0"
}
variable "l_node_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 2
}
variable "l_node_vlans" {
  type    = set(string)
  default = [246]
}
variable "l_node_plan" {
  type        = string
  description = "Metal server type you plan to deploy"
  default     = "c3.medium.x86"
}
