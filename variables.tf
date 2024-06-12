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

variable "server_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 4
}

variable "vlan_count" {
  type        = number
  description = "Terraform managed MinIO VLANs"
  default     = 4
}

variable "metal_nodes_tags" {
  type    = list(string)
  default = ["MSUBNET_172.16.248","MVLAN_1000"]
}
