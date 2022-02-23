# Project Organization
Our project file is getting pretty unwieldly. Lets refactor to make the project more organized. We'll create a new project to host these changes.

The complete example can be found in the [organize](../organize) folder.

## Modules/Projects
First things first, lets create a folder structure for our configs. We will store the configuration for our application in an dev folder. This will represent the environment we're  If we create another environment we can create another folder at that level. Under the modules folder we will store all the generic components.

There are a few new items here that we'll talk about in a bit. You'll see a `tfvars` file, this is how we will pass variables into the application. You'll also see `variables.tf` and `output.tf` throughout the folders. These are how we handle input/outputs to/from modules.

This structure is not prescribed. Use the folder structure that makes sense in your situation.

```
|-- dev
|   |-- main.tf
|   |-- variables.tf
|   |-- terraform.tfvars
|
|-- modules
|   |-- aws
|   |   |-- backend
|   |   |   |-- main.tf
|   |   |   |-- variables.tf
|   |   |   |-- output.tf
|   |   |-- ec2
|   |   |   |-- main.tf
|   |   |   |-- variables.tf
|   |   |   |-- output.tf
|   |
|   |-- gcp
|   |   |-- compute
|   |   |   |-- main.tf
|   |   |   |-- variables.tf
|   |   |   |-- output.tf
```

We can start by moving the backend code into the aws/backend folder. Then do so for each other resource.

*`/modules/aws/backend/main.tf`*

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
```

Then in dev/main.tf, import the modules using the module syntax. Source points to the module folder we're importing.

```tf
# Modules
module "backend" {
  source = "../modules/aws/backend"
}
module "ec2" {
  source = "../modules/aws/ec2"
}
module "compute" {
  source = "../modules/gcp/compute"
}
```

Third-party modules are also available such as the [AWS VPC module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest). Below is an example showing the source syntax.

```tf
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  # etc...
}
```

At this point we can enter into the dev folder, init, and apply our app changes!

## Locals
We can store references to local variables using "locals" and use the values throughout the file. Its a quick way to make your module easier to use.

In `modules/gcp/compute/main.tf`, lets add a locals block to the top of the file.

```tf
locals {
  region = "us-east1"
  machine_type = "e2-micro"
}
```

Then we can use the locals like so:
```tf
resource "google_compute_instance" "test_gcp_instance" {
  name         = "test-gcp-instance-${local.region}"
  machine_type = local.machine_type
  zone         = "${local.region}-b"
  # ...
```

We're using string interpolation to insert the local variables into the strings. (`"test-gcp-instance-${local.region}"`) We can also directly use the local value directly, as we do with `machine_type`.

## Variables
We can create `variable.tf` files that allow us to pass variables into modules. Lets add a variables file to the `modules/aws/ec2/main.tf`. The contents will be:

```tf
variable "env" {
  description = "Environment name"
  default = "dev"
  type = string
}
```

This allows us to pass an "env" into the module definition in `dev/main.tf`.

```tf
module "ec2" {
  source = "../modules/aws/ec2"
  env = "dev"
}
```

Now we can use that variable inside of our ec2 file by doing a lookup on `var`.
```tf
tags = {
  name: "Test server"
  env: var.env
}
```

I'll go ahead and add that variable to the other modules too.

## Outputs
When information inside a module is needed in other modules, we can use outputs to export the variable from the module.

First, I'll add `modules/aws/vpc/main.tf`. It will create

```tf
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-2a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.env
  }
}
```

Now I want to add our EC2 instance to the public subnet. So I'll output the public subnet id. I'll make a new file called `modules/aws/vpc/output.tf`.

```tf
output "public_subnet_id" {
  description = "id of our public subnet"
  value = vpc.public_subnets[0]
}
```

We're referencing outputs of the "terraform-aws-modules/vpc/aws" module here as well.

We have to add our new `vpc` module to the `dev/main` folder.
```tf
module "vpc" {
  source = "../modules/aws/vpc"
  env = "dev"
}
```

Then we pass the output into the ec2 instance.
```tf
module "ec2" {
  source = "../modules/aws/ec2"
  env = "dev"
  subnet = vpc.public_subnet_id
}
```

Add a new variable to the ec2 module
```tf
variable "subnet" {
  description = "Subnet ID"
  type = string
}
```

Then modify the EC2 instance to use the subnet.
```diff
resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"
++  subnet_id = var.subnet
```

## Passing external variables
Sometimes we want to pass in variables from outside of the configs, such as from the commandline. This can be particularly helpful when creating separate environments that run off the same configs.

I'll add a file called `dev/variables.tf` that allows us to pass in a variable.
```tf
variable "env" {
  description = "Environment name"
  default = "dev"
  type = string
}
```

With in `dev/main.tf` I'll reference the variable.
```tf
module "backend" {
  source = "../modules/aws/backend"
  env = var.env
}
# etc...
```

Now when calling apply, I can pass in that variable.
```
terraform apply -var="env=dev"
```

I can also create a `.tfvars` file instead and use that when calling apply.

`dev/dev.tfvars`
```
env = "dev"
```

Then call apply with that variable file
```
terraform apply -var-file="dev.tfvars"
```

Or I can create environment variables that always are available.

```
export TF_VAR_env=dev
```

[Next: Expressions](EXPRESSIONS.md)
