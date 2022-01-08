variable "repository" {}
variable "tag" {}
variable "assetName" {}

variable "token" {
  sensitive = true

  default = null
}

variable "bucket" {}
variable "key" {}

variable "function_name" {}
variable "role_name" {}

variable "timeout" {
  default = 300
}

variable "memory_size" {
  default = 128
}
