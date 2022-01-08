locals {
  result = jsondecode(data.aws_lambda_invocation.copier.result)
}

output "bucket" {
  description = "The S3 bucket name."
  value       = local.result.bucket
}

output "key" {
  description = "The S3 key."
  value       = local.result.key
}
