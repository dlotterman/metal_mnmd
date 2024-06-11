variable "auth_token" {
  type        = string
  description = "Your Equinix Metal API key (https://console.equinix.com/users/-/api-keys)"
  sensitive   = true
}

variable "project_id" {
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
  default     = "ny"
}

variable "server_count" {
  type        = number
  description = "numbers of backend nodes you want to deploy"
  default     = 4
}

variable "m_node_vlans" {
  description = "VLANs for MinIO"
  type        = list(string)
  default     = [3870, 3873, 3895]
}