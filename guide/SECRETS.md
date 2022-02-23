# Secrets
You know the rule: Do not store your username and passwords in plain text.

Lets discuss some ways to keep secrets safe.

## Secrets get stored in state
No matter what, secrets get stored in state. For that reason your backend should be secure. In the state example we set up encryption at rest.

```tf
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
```

Also use the `encrypt = true` argument when connecting the back end.
```tf
terraform {
  # ...

  backend "s3" {
    encrypt = true
    bucket = "terraform-state-bucket-2202022"
    key = "terraform-state/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "terraform-state-lock-2202022"
  }
}
```

You can further secure the S3 bucket by using IAM or other policies to limit who can access the S3 bucket. Even limiting access to a single deployment server.

## Environment Variables
We can pass in environment variables so that nothing gets committed to code. Terraform even allows us to include a `sensitive` flag to keep the variables out of the logs.

```tf
variable "user" {
  description = "Database username"
  type = string
  sensitive = true
}

variable "password" {
  description = "Database password"
  type = string
  sensitive = true
}
```

Then I can export them as environment variables.
```
export TF_VAR_user=admin
export TF_VAR_password=password1
```

Third-party secret managers can pick up the work from here.

