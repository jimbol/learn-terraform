# Terraform State
The current state of the back-end application gets stored in a file called `terraform.tfstate`. This file is JSON and represents, in explicit declarative form, each resource. Looking at our tfstate we can see each of the elements we have created.

The complete example can be found in the [state](../state) folder.

## Metadata
In addition to the descriptions of real-world resources, tfstate holds on to metadata about resources. For example, if a resource depends on another resource, the dependency will be tracked in tfstate. This information is used during `tf apply` to manage the order that resources are deployed. We'll see later that we can add a `depends_on` meta argument to resources, this also gets captured in tf state.

## Collaboration and Backends
Right now, the terraform state would be included in my git repository. But because tfstate represents what is live in production, theres no guarentee that the version you pull from git will be up to date. Also, if multiple people are modifying the state at the same time, collisions can occur in the code, and worse, in the cloud.

For these reasons, Terraform allows us to set up backends (see the [backend documentation](https://www.terraform.io/language/settings/backends)). Backends are a centralized location for our tfstate that exists outside of the normal source control. The remote tfstate is kept up-to-date with what has been deployed and utilizes a lock when updating to prevent overwrites. All team members pull from this one state file.

There are many backend services available. Asurerm, AWS S3/DynamoDB, Postgres, Google Cloud Storage, etc. Today, we'll use S3/DynamoDB.

First we need an S3 bucket. This is where the tfstate file will actually be stored.

```tf
resource "aws_s3_bucket" "terraform_backend" {
  bucket = "terraform-state-bucket"

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
```

Then we need to create a DynamoDB table to house the state lock. Again, the lock is used to prevent multiple people from making changes at the same time.

```tf
resource "aws_dynamodb_table" "terraform_state_lock" {
  name = "terraform-state-lock"

  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

At this point, we need to apply the changes. The bucket needs to exist before we can set up the actual backend functionallity.

```
terraform apply
```

Once thats done, we must modify the `terraform` block to use S3 as our backend.

```tf
terraform {
  # ...
  backend "s3" {
    encrypt = true
    bucket = "terraform-state-bucket"
    key = "terraform-state/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-state-lock"
  }
}
```

Now we run `terraform init`, we will be asked if we want to move our state to S3. Yes we do! Once that is done, we're all set! The state is now stored in S3 instead of locally.

[Next: Organizing Our Project](ORGANIZE_PROJECT.md)
