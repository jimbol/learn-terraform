terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~>4.0"
    }
  }

  # backend "s3" {
  #   encrypt = true
  #   bucket = "terraform-state-bucket-2202022-a"
  #   key = "terraform-state/terraform.tfstate"
  #   region = "us-east-2"

  #   dynamodb_table = "terraform-state-lock-2202022-a"
  # }
}

# Providers
provider "aws" {
  region  = "us-east-2"
  profile = "default"
}

provider "google" {
  credentials = file(pathexpand("~/.config/gcloud/terraform-class-327014.json"))
  region      = "us-east1"
  project     = "terraform-class-327014"
}

# Modules
module "backend" {
  source = "../modules/aws/backend"
  env    = var.env
}
module "vpc" {
  source = "../modules/aws/vpc"
  env    = var.env
}
module "ec2" {
  source = "../modules/aws/ec2"
  env    = var.env
  subnet = module.vpc.public_subnet_id
}
module "compute" {
  source = "../modules/gcp/compute"
  env    = var.env
}



