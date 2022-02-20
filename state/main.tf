terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>3.0"
    }
    google = {
      source = "hashicorp/google"
      version = "~>4.0"
    }
  }

  backend "s3" {
    encrypt = true
    bucket = "terraform-state-bucket-2202022"
    key = "terraform-state/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-state-lock-2202022"
  }
}

provider "aws" {
  region = "us-east-2"
  profile = "default"
}

resource "aws_s3_bucket" "terraform_backend" {
  bucket = "terraform-state-bucket-2202022"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "terraform-state-lock-2202022"

  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}

resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  tags = {
    name: "Test server"
  }
}

# Google Cloud infrastructure
provider "google" {
  credentials = file(pathexpand("~/.config/gcloud/terraform-class-327014.json"))
  region = "us-east1"
  project = "terraform-class-327014"
}

resource "google_compute_instance" "test_gcp_instance" {
  name         = "test-gcp-instance-us-east1"
  machine_type = "e2-micro"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }
}
