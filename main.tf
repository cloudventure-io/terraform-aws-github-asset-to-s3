locals {
  bucket_arn = "arn:aws:s3:::${var.bucket}"
}

resource "aws_cloudwatch_log_group" "copier" {
  name              = "/aws/lambda/${aws_lambda_function.copier.function_name}"
  retention_in_days = 30
}

data "aws_iam_policy_document" "copier_lambda_access" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = [
      "${local.bucket_arn}/${dirname(var.key)}/*",
    ]
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [local.bucket_arn]
  }
}

module "lambda_role" {
  source  = "spirius/iam-role/aws"
  version = "~> 2.0"

  name                 = var.role_name
  assume_role_services = ["lambda.amazonaws.com"]
  managed_policy_arns  = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
  access_policy        = { json = data.aws_iam_policy_document.copier_lambda_access.json }
}

module "nodejs_fetch" {
  source  = "cloudventure-io/fetch/nodejs"
  version = "1.1.0"
}

module "package" {
  source  = "cloudventure-io/package/nodejs"
  version = "1.0.0"

  files = [{
    path    = "${path.module}"
    include = ["src/*.js", "LICENSE", "package.json"]
    exclude = ["\\.test\\.js$"]
  }]

  modules = [module.nodejs_fetch]
}

data "archive_file" "copier_lambda_code" {
  type        = "zip"
  output_path = "${path.module}/copier-lambda.zip"

  dynamic "source" {
    for_each = module.package.files

    content {
      filename = source.key
      content  = file(source.value)
    }
  }
}

resource "aws_lambda_function" "copier" {
  filename         = data.archive_file.copier_lambda_code.output_path
  source_code_hash = data.archive_file.copier_lambda_code.output_base64sha256
  function_name    = var.function_name
  role             = module.lambda_role.role.arn
  handler          = "src/index.handler"
  runtime          = "nodejs14.x"
  timeout          = var.timeout
  memory_size      = var.memory_size
  publish          = true
}

data "aws_lambda_invocation" "copier" {
  function_name = aws_lambda_function.copier.function_name
  qualifier     = aws_lambda_function.copier.version

  input = jsonencode({
    bucket = var.bucket
    key    = var.key

    repository = var.repository
    tag        = var.tag
    assetName  = var.assetName

    token = var.token
  })
}
