terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
  }
}

# Providers
provider "aws" {
  region  = "us-east-2"
  profile = "default"
}

provider "aws" {
  alias = "usw1"
  region  = "us-west-1"
  profile = "default"
}

# Modules
module "ec2" {
  source = "../modules/ec2"
  env    = var.env
}

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "lambda_east" {
  source = "../modules/lambda"
  role_arn = aws_iam_role.lambda_exec.arn
}

module "lambda_west" {
  source = "../modules/lambda"
  role_arn = aws_iam_role.lambda_exec.arn
  providers = {
    aws = aws.usw1
  }
}
