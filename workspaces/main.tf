
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>3.27"
    }
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}

resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  tags = {
    Name: "${terraform.workspace} test server"
  }
}
