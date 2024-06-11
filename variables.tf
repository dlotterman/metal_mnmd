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


variable "m_node_vlans" {
  description = "VLANs for MinIO"
  type        = map(object({
				VLAN=optional(number)
				UUID=optional(string)
				}))
  //default	  = [3780, 3880, 3883]
default     = {"INTER_B"={VLAN=3873,UUID="fd81ca81-04cc-4783-a4f9-422f20cec4f6"},"STOR_A"={VLAN=3870,UUID="056d8a96-a509-4f4e-8ce5-a347960d013e"}}
}

// variable "m_node_vlans" {
  // type = list(object({
    // vxlan = number
    // external = number
    // protocol = string
  // }))
  // default = [
    // {
      // internal = 8300
      // external = 8300
      // protocol = "tcp"
    // }
  // ]
// }