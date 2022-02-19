# Terraform Configuration Grammar
## About
### HashiCorp Configuration Language
The Terraform configuration language is a superset of the HashiCorp Configuration language or HCL. HCL is used for other tools created by HashiCorp as well.

### Declarative
One key aspect of Terraform's language is that it is *declarative*. The code will be interpeted the same way every time we run it. There is no runtime logic, code forking, or loops. No off-by-1 errors.

## Blocks, Arguments, and Identifiers
### Blocks
Blocks are the chuncks of code that do things in Terraform. For example, the following block has the `resource` block type.

```
resource "aws_instance" "test_instance" {}
```

Each block type defines how many *labels* are expected after the type. In this case, `resource` expects 2 labels: The resource type and the resource name.

### Arguments
Inside the `{}` we can include arguments as seen below.

```
resource "aws_instance" "test_instance" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  tags = {
    name: "test server"
  }
}
```

The arguments depend on the particular block type. Variable blocks allow type, default, and description arguments. Resource arguments are determined by their definition from the provider. For example, see the [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) resource.

### Identifiers
Argument names, block type names, and labels are all know as identifiers. Pretty much its a name for any given item in Terraform.

### Comments
There are 3 comment types. The first two are single line, the last is for multi-line comments.
```
# comment
// comment
/* comment */
```

[Next: Workflow](WORKFLOW.md)
