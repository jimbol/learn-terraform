# Meta-Arguments
Available on every module and resource are a set of "meta-arguments" that allow you to create multiple versions of the module or resource.

- `depends_on` - Make explicit an implicit dependency
- `count` - Make like copies
- `for_each` - Make different copies
- `providers` - Handle different providers

The complete example can be found in the [meta-arguments](../meta-arguments) folder. Let's prepare this folder structure before continuing.

## `depends_on`
`depends_on` make explicit an implicit dependency. Meaning if the dependency is described via references, we can manually create a reference. This connection gets stored in tfstate and enforces an order of deployment.

Frequently, this isn't needed. For example, lets say we want to add a security group to our EC2 instance. Inside `modules/ec2` lets add the security group.

```tf
resource "aws_security_group" "allow_load_balancer_access" {
  name = "allow_load_balancer_access"
  description = "Allows connections from load balancer and access to the internet"

  ingress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "loadbalancer ingress"
    protocol = "tcp"
    from_port = 8000
    to_port = 8000
    self = false

    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]

  egress = [{
    cidr_blocks = ["0.0.0.0/0"]
    description = "internet egress"
    protocol = "-1"
    from_port = 0
    to_port = 0

    self = false
    ipv6_cidr_blocks = []
    security_groups  = []
    prefix_list_ids = []
  }]
}
```

And then modify the `aws_instance` to use the security group

```diff
resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

++  vpc_security_group_ids = [aws_security_group.allow_load_balancer_access.id]

  tags = {
    name: "Test server"
    env: var.env
  }
}
```

Here an explicit connection is being created when we reference the security group: `aws_security_group.allow_ssh.id`. That gets tracked in the tfstate.

But lets say the EC2 instance runs a boot script that stores information in an S3 bucket. We will need to create the S3 bucket in `modules.ec2`.

```tf
resource "aws_s3_bucket" "instance_information" {
  bucket = "instance-information-store"
}
```

Right now, there is a chance that when the EC2 instance boots, the S3 bucket won't be there. Lets create an explicit dependency to address that.

```diff
resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  vpc_security_group_ids = [aws_security_group.allow_load_balancer_access.id]
  depends_on = [aws_s3_bucket.instance_information]

  tags = {
    name: "Test server"
    env: var.env
  }
}
```

Looking at the tfstate file we can spot the dependency under the `dependencies` key.

## `count`
Perhaps 1 instance isn't enough. Maybe we need to run multiple instances running our application. Enter, the `count` meta-argument. I want 3 copies of this instance, so I'll add `count = 3`.

```diff
resource "aws_instance" "test_server" {
++  count = 3
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  vpc_security_group_ids = [aws_security_group.allow_load_balancer_access.id]
  depends_on = [aws_s3_bucket.instance_information]

++  user_data = <<-EOF
++    #!/bin/bash
++    python3 -m http.server
++  EOF

  tags = {
++    name: "Test server ${count.index}"
--    name: "Test server"
    env: var.env
  }
}
```

The `user_data` block is specific to `aws_instance`. It allows us to define a bootup script.

Now when we deploy, we will create 3 instances instead of just one.

Let's add a load balancer to delegate work between the instances.

```tf
resource "aws_elb" "test_load_balancer" {
  name               = "test-load-balancer"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]

  listener {
    instance_port     = 8000 # assumes an application is running at port 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = aws_instance.test_server[*].id
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "test-server-terraform-elb"
  }
}
```

Now we can see our load balancer in the console that is directing traffic to the 3 instances. We can adjust this at will.

## `for_each`
If we want to create several resources that aren't the same, we can use `for_each` to loop through a list definitions and create resources for each. In this example we will create a couple of lambda functions.

First lets create the lambda handlers. I'm making a new top-level folder called `src` to house our handlers. We'll call the handlers `src/foo/foo.js` and `src/bar/bar.js`.

Each file will look something like this.
`foo.js`
```es6
module.exports.handler = async (event) => {
  console.log('EVENT: ', event);
  let message = 'Foo was called!';

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message,
    }),
  }
}
```

Next I'll make a module for the Lambda Terraform configs. `modules/lambda/main.tf`.

I'll store the lambda names in locals.
```tf
locals {
  lambdas = ["foo", "bar"]
}
```

Then we're going to use `for_each` and a new type of block called `data`. `data` blocks provide access to data sources. This particular block creates a zip of for files at a given path. We'll get into more uses for `data` later on.

```tf
data "archive_file" "lambda_definitions" {
  for_each = toset(local.lambdas)

  type = "zip"
  source_dir  = "${path.module}/../../src/${each.key}"
  output_path = "${path.module}/../../build/${each.key}.zip"
}
```

The `for_each` meta-argument is being used here. We're converting the lambdas local to a set, which is like an unordered list, and passing the result into the `for_each` argument. This provides access to the `each` identifier within the block.

When defining `source_path` and `output_path`, we use `each.key` to use the set items, the strings `foo` and `bar`.

Now lets create an S3 bucket and upload both lambdas to that bucket.

```tf
resource "aws_s3_bucket" "lambda_zip_files" {
  bucket = "lambda-zip-files"
}

# Note: aws_s3_object became available in AWS provider version 4+.

resource "aws_s3_object" "lambda_zip" {
  for_each = toset(local.lambdas)

  bucket = aws_s3_bucket.lambda_zip_files.id

  key    = "${each.key}.zip"
  source = data.archive_file.lambda_definitions[each.key].output_path

  etag = filemd5(data.archive_file.lambda_definitions[each.key].output_path)
}
```

Again, we're using `for_each` to create an S3 object for each zip file. You can see how we do identifier lookups using `each.key`.
```
data.archive_file.lambda_definitions[each.key].output_path
```

Then we'll add the lambda in the same manor.

```tf
resource "aws_lambda_function" "foobar_lambdas" {
  for_each = toset(local.lambdas)

  function_name = each.key

  s3_bucket = aws_s3_bucket.lambda_zip_files.id
  s3_key    = aws_s3_object.lambda_zip[each.key].key

  runtime = "nodejs12.x"
  handler = "${each.key}.handler"

  source_code_hash = data.archive_file.lambda_definitions[each.key].output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}
```

Finally, including some IAM role information to allow the lambda to access S3 and execute.

```tf
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

We can now see and test these in the AWS Console!

## `provider`
What happens when we want to include multiple provider configurations? For example, deploying our resources to multiple AWS regions: `us-east-1` and `us-west-1`? Well Terraform has created the `providers` meta-argument to handle this use case.

For this example, we're going to deploy our Lambdas in multiple regions.

First lets move `aws_iam_role.lambda_exec` to the outside scope. IAM roles are global and are shared across regions. Then we can pass the roles in as a variable.

Next lets create our new provider.

```tf
provider "aws" {
  region  = "us-east-2"
  profile = "default"
}

provider "aws" {
  alias = "usw1"
  region  = "us-west-1"
  profile = "default"
}
```

The first provider is our default. The second has an `alias` argument, giving the provider a name and indicting that it is not the default.

Next we'll make a second lambda module block with the providers meta-argument.

```tf
module "lambda_east" {
  source = "../modules/lambda"
  role_arn = aws_iam_role.lambda_exec.arn
}

module "lambda_west" {
  source = "../modules/lambda"
  role_arn = aws_iam_role.lambda_exec.arn
  providers = {
    aws = aws.usw1
  }
}
```

The first lambda still uses our default AWS provider. The second will use our new provider.

The S3 bucket inside our lambda module cannot have the same name between regions. We'll use something called `random_pet` that is provided by HashiCorp to gve the bucket a random id.

```tf
resource "random_pet" "bucket" {}

resource "aws_s3_bucket" "lambda_zip_files" {
  bucket = "lambda-foobar-zip-files-${random_pet.bucket.id}"
}
```

Lastly, we can add the following to `required_providers` in our `terraform` block.

```tf
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
```

Now we can deploy to both regions! Super powerful stuff!

[Next: Data Sources](DATA_SOURCES.md)
