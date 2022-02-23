# Data Sources
Data sources pull data into Terraform from outside sources. We already saw one example of this where we pull in external files as zip files.

```tf
locals {
  lambdas = ["foo", "bar"]
}

data "archive_file" "lambda_definitions" {
  for_each = toset(local.lambdas)

  type = "zip"
  source_dir  = "${path.module}/../../src/${each.key}"
  output_path = "${path.module}/../../build/${each.key}.zip"
}
```

We pull in a special data resource by declaring a data block. The first argument of the data block is the data source and the second is what we'll refer to it as. What goes inside the data source depends on the provider that supports it.

The complete example can be found in the [data-sources](../data-sources) folder.

## Availability Zones and Region
Lets use AWS's provider to find availability zones in the current region. After creating our provider and terraform blocks, write the following.

```tf
data "aws_availability_zones" "available" {
  state = "available"
}

output "available_zones" {
  value = data.aws_availability_zones.available
}
```

This will output a lot of info about the azs in our current region. We can drill down into that data using dot lookups.
```tf
output "available_zone_names" {
  value = data.aws_availability_zones.available.names
}
```

Similarly, we can get the current region.

```tf
data "aws_region" "current" { }
```

These configurations can be used along with the provider meta-argument to create truly global infrastructure.

## Available AMIs
Lets say we want to create multi-region EC2 instances. Each region has different AMIs, different image ids, for EC2 images. So the AMI we use in us-east-1 will not be present in us-west-1.

Lets use data sources to get region images. I'll filter by name so that we can find the 64-bit x86 machine.

```tf
data "aws_ami" "linux_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "linux_ami" {
  value = data.aws_ami.linux_ami
}

output "linux_ami_id" {
  value = data.aws_ami.linux_ami.id
}
```
This id will be relative to the region selected in a given module. So we can guarentee that the AMI will be valid.

Then we can use it to create an EC2 instance.

```tf
resource "aws_instance" "test_server" {
  ami = data.aws_ami.linux_ami.id
  instance_type = "t2.nano"

  key_name = "terraformclass"

  tags = {
    name: "Test server"
  }
}
```

One thing to note with this approach, if the AMI changes, your instance may be destroyed and replaced. Its helpful to think of all instances as temporary when using this approach.

## Local data sources
Other data sources are handled locally, such as the original zip example. Creating a template is another example.

I created a tpl template file.
```
#!/bin/bash

echo "AWS_REGION = ${aws_region}"
```

I have to run `terraform init`. Then I can use the template to generate a script.

```tf
data "aws_region" "current" {}

data "template_file" "init" {
  template = "${file("${path.module}/script.tpl")}"
  vars = {
    aws_region = "${data.aws_region.current.name}"
  }
}

output "script" {
  value = data.template_file.init
}
```

I can also read in files with the `local_file` data source. Again, I have to run `terraform init` to read the local file.

```
data "local_file" "script_template" {
  filename = "${path.module}/script.tpl"
}

output "script_template" {
  value = data.local_file.script_template
}
```

[Next: Secrets](SECRETS.md)
