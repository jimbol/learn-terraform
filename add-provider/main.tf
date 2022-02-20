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
}

provider "aws" {
  region = "us-east-2"
  profile = "default"
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
