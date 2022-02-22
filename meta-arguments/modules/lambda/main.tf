locals {
  lambdas = ["foo", "bar"]
}

data "archive_file" "lambda_definitions" {
  for_each = toset(local.lambdas)

  type = "zip"
  source_dir  = "${path.module}/../../src/${each.key}"
  output_path = "${path.module}/../../build/${each.key}.zip"
}

resource "random_pet" "bucket" {}

resource "aws_s3_bucket" "lambda_zip_files" {
  bucket = "lambda-foobar-zip-files-${random_pet.bucket.id}"
}

resource "aws_s3_object" "lambda_zip" {
  for_each = toset(local.lambdas)

  bucket = aws_s3_bucket.lambda_zip_files.id

  key    = "${each.key}.zip"
  source = data.archive_file.lambda_definitions[each.key].output_path

  etag = filemd5(data.archive_file.lambda_definitions[each.key].output_path)
}

resource "aws_lambda_function" "foobar_lambdas" {
  for_each = toset(local.lambdas)

  function_name = each.key

  s3_bucket = aws_s3_bucket.lambda_zip_files.id
  s3_key    = aws_s3_object.lambda_zip[each.key].key

  runtime = "nodejs12.x"
  handler = "${each.key}.handler"

  source_code_hash = data.archive_file.lambda_definitions[each.key].output_base64sha256

  role = var.role_arn
}

