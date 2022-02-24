# Workspaces
What happens when we want to create different environments based on the same config?

There are a couple of main approaches:
1. Use folders like `dev` and `prod` and create separate base configs.
2. Use workspaces and power multiple environments using one config.

In this section we will use Workspaces to create multiple versions of our state.

The complete example can be found in the [workspaces](../workspaces) folder.

## Workspace commands
If you haven't already, call `terraform init` and `terraform apply`. You will see your tfstate file was created. Now lets create a workspace.

We can first check for workspaces.

```
terraform workspace list
```

Shows only the default workspace.

```
* default
```

Add one with the `new` command.
```
terraform workspace new dev
```

And list the workspaces again
```
terraform workspace list
```
Shows
```
  default
* dev
```

Take a look at your folder structure and you'll see `terraform.tfstate.d/dev` has appeared. This is where Terraform will keep track of the dev workspace's state.

You can switch workspaces like so
```
terraform workspace select default
terraform workspace select dev
```

All the workspace commands are pretty understandable: New, list, show, select and delete.

## Using workspace in configs
We can include the workspace name in the configs.

```diff
resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "terraformclass"

  tags = {
++    Name: "${terraform.workspace} test server"
--    Name: "test server"
  }
}
```

We can run logic off of this such as:
```
Name: "${terraform.workspace == "prod" ? "Production" : "Development"} test server"
```

## Use workspace tfvars
Its common to use separate tfvars files for separate workspaces.

Lets make a variables file
```tf
variable "region" {
  description = "Application Region"
  default     = "us-east-2"
  type        = string
}
```

and a couple tfvars files
`dev.tfvars`
```tf
region = "us-east-2"
```

`prod.tfvars`
```tf
region = "us-west-1"
```
(We have to make a prod workspace too: `terraform workspace new prod`)

Then we can use the `-var-file` flag to pass in the proper var file for a workspace.

```
terraform plan -var-file dev.tfvars
```

Or we can use `terraform workspace show` as an input to load the proper var file.
```
terraform plan -var-file "$(terraform workspace show).tfvars"
```

This is super cool because it allow for branches of infrastructure. You could make feature branches of infrastructure as its being developed. Or store specific configs under each workspace, such as a globally available S3 bucket.

