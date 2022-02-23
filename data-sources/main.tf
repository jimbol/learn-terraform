terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>3.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  profile = "default"
}

# AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# output "available_zones" {
#   value = data.aws_availability_zones.available
# }
# output "available_zone_names" {
#   value = data.aws_availability_zones.available.names
# }

# ###
# # Region
# data "aws_region" "current" {}

# output "aws_region" {
#   description = "AWS region"
#   value       = data.aws_region.current
# }

###
# EC2 Linux AMI
# data "aws_ami" "linux_ami" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }
# }

# output "linux_ami" {
#   value = data.aws_ami.linux_ami
# }
# output "linux_ami_id" {
#   value = data.aws_ami.linux_ami.id
# }

# resource "aws_instance" "test_server" {
#   ami = data.aws_ami.linux_ami.id
#   instance_type = "t2.nano"

#   key_name = "terraformclass"

#   tags = {
#     name: "Test server"
#   }
# }

# ###
# # Templates
# data "aws_region" "current" {}

# data "template_file" "init" {
#   template = "${file("${path.module}/script.tpl")}"
#   vars = {
#     aws_region = data.aws_region.current.name
#   }
# }

# output "script" {
#   value = data.template_file.init
# }

# ###
# # Script
# data "local_file" "test_text" {
#   filename = "${path.module}/test.txt"
# }

# output "test_text" {
#   value = data.local_file.test_text
# }
