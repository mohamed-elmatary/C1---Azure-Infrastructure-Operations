variable "vm_count" {
  default = 2
}

variable "resource_group_name" {
  type = string
  default = "myResourceGroup"
}

variable "location" {
  type = string
  default = "East US"
}