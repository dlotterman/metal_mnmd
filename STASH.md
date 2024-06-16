```
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
```


```
variable "m_node_vlans" {
  description = "VLANs for MinIO"
  type        = map(object({
				VLAN=optional(number)
				UUID=optional(string)
				}))
default     = {"INTER_B"={VLAN=3873,UUID="UUID-EXAMPLE-4783-a4f9-422f20cec4f6"},"STOR_A"={VLAN=3870,UUID="UUID-EXAMPLE-4f4e-8ce5-a347960d013e"}}
}


```
```
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
```
