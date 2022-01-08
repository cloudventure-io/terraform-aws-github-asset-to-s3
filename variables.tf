variable "repository" {
  description = "The repository location in the format org/repo."
}

variable "tag" {
  description = "The tag name, e.g. v1.0.0."
}

variable "assetName" {
  description = "The name of the asset file, e.g. asset.zip."
}

variable "token" {
  description = "The github token, used for private repositories."
  sensitive   = true
  default     = null
}

variable "bucket" {
  description = "S3 bucket name where asset will be copeid."
}

variable "key" {
  description = "S3 key where asset will be copied."
}

variable "function_name" {
  description = "The lambda function name."
}

variable "role_name" {
  description = "The IAM role name."
}

variable "timeout" {
  description = "Lambda function timeout."
  default     = 300
}

variable "memory_size" {
  description = "Lambda function memory size."
  default     = 128
}
