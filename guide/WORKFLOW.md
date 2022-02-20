# Workflow
Next we'll learn about the Terraform workflow by creating and deploying an EC2 instance.

The complete example can be found in the [workflow](../workflow) folder.

## Configuration
First lets create a configuration. Here we are using 3 different block types: terraform, provider, and resource.

```tf
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~>3.27"
    }
  }

  required_version = ">= 0.14.9"
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
```

### Terraform Block
The opening `terraform {}` block is a sort of requirements declaration for the project. This is where we can tell Terraform which providers, and which versions of providers are required in the project. (more on providers below) The `required_providers` block lets us pass in providers with version constraints.

Providers include a library of resources available. There are different versions of each provider. Restricting the version is important for maintaining consistent configuration across machines. If you don't include a provider version, Terraform will try to pick the latest. This can cause mis-matches across machines. If the project uses more than one cloud provider, you can include the definition for each here.

### Provider Blocks
The `provider {}` block defines a specific provider. If we have multiple providers such as AWS *and* Google Cloud, then we will have a separate block for each. Also, if we are working with different regions in AWS, we will need a separate provider block for each. In our case, we provide a profile to give our provider our credentials, and a region to tell the provider where we want this to be deployed to.

### Resources
The `resource` block is used to define resources in our infrastructure. In this example we are creating an `aws_instance` and calling it `test_server`. The name `test_server` needs to be unique within our configs. Elsewhere in the configs we can use this name as a reference: `aws_instance.test_server`. `aws_instance` has many outputs that we can reference as well: `aws_instance.test_server.id`.

The definition of `aws_instance` is given by the AWS provider. Terraform provides a reference document for all supported resources.

## Set up
Before we get into the workflow, we have to have [install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) and [configure](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) aws-cli. You will need an aws profile with access to create resources.

## CLI Workflow
The workflow in Terraform is simple and powerful. The commandline tool is focused on the basics while the configurations focus on the specifics.

### Initialize
```
terraform init
```

Once your configuration is ready, run `terraform init`. This creates a `.terraform` directory and installs the required provider. You will have run this again when importing modules or other providers. More on that later.

### Plan
```
terraform plan
```

Another optional step is to run `terraform plan` this will display the execution plan. It compares your configuration with what exists in the cloud without risking a deploy. You can use this to review your changes.

### Apply
```
terraform apply
```

Deploying our infrastructure is as simple as running `terraform apply`, this will check formatting, validate the configs, and show the execution plan. You will be prompted to review the execution plan and type "yes" if you are ready to create the resources.

If everything works you'll see a message like `Apply complete! Resources: 1 added, 0 changed, 0 destroyed.`

When we make a change to the configuration, we can deploy the changes with `terraform apply`. Let's change the instance type.

```diff
--  ami = "ami-0f19d220602031aed"
++  ami = "ami-0b614a5d911900a9b"
```

Then run `terraform apply`. You can see this change will require the instance be torn down and recreated. Other changes can happen without tearing down the resource. Pay close attention when deploying production code to avoid taking down your applications. Or better yet, set up your application to allow replacement of resources without going down.

### Destroy
```
terraform apply -destroy
```

When we no longer need infrastructure, we can destroy it permanently using `terraform apply -destroy` or `terraform destroy`. There is no turning back once this runs, though, we can always use our configuration to spin up our project again.

### Format and Validate
```
terraform fmt
terraform validate
```

An optional step you can take is to run `terraform fmt` to check for any malformated files. `terraform validate` will determine if your configuration is valid. This checks for things like syntax errors or missing references, resources, and modules.

[Next: Add another Provider and Resource](ADD_PROVIDER_RESOURCE.md)
