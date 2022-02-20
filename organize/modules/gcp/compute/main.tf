locals {
  region = "us-east1"
  machine_type = "e2-micro"
}

resource "google_compute_instance" "test_gcp_instance" {
  name         = "test-gcp-instance-${local.region}-${var.env}"
  machine_type = local.machine_type
  zone         = "${local.region}-b"

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
