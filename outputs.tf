locals {
  result = jsondecode(data.aws_lambda_invocation.copier.result)
}

output "bucket" {
  value = local.result.bucket
}

output "key" {
  value = local.result.key
}
