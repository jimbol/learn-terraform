# Add another provider
Let's practice adding another provider. You can have one or many providers for a given project.

The complete example can be found in the [add-provider](../add-provider) folder.

## Add Google Cloud to Terraform Block
First we can update the terraform block to lock us into a major version of the Google provider.

```tf
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
```

Both AWS and Google co-manage the providers, so we can be sure the implementation is sound.


## Add Google Cloud provider
To continue we need a Google Cloud "project" and credentials on our computer. [Here is a guide to setting up a Google Cloud project.](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

Lower in our file we can include the Google Cloud provider.

```tf
# Google Cloud infrastructure
provider "google" {
  credentials = file(pathexpand("~/.config/gcloud/terraform-class-327014.json"))
  region = "us-east1"
  project = "terraform-class-327014"
}
```

## Add Google compute instance
Now that the Google cloud provider has been included, we can add a compute instance.

```tf
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
```

We can use the gcloud cli to connect to that instance. [Here is a guide to set up gcloud cli](https://cloud.google.com/sdk/docs/install).

```
gcloud compute ssh --zone "us-east1-b" "test-gcp-instance-us-east1"  --project "terraform-class-327014"
```

## Resource Arguments, Requirements, and Implementation
Resources in Terraform tend to be very well documented. We can see the docs for google_compute_instance [here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_instance).

We can see the all the argument options. There are a lot of them because we can do a lot with google_compute_instance. But we really only need the *required* arguments in order to deploy something.

All this information is tied to the provider. Given a valid configuration, the provider will call the gcloud commands required deploy the infrastructure.

1. It compares what is in the configurations with what is live in the cloud.
2. It prepares a list of changes that need to be made.
3. It uses Google's Cloud Shell to make changes to GCP.

[Next: State](STATE.md)
