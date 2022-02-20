# Introduction
## What is infrastructure as code
Rather than managing infrastructure in a GUI like the AWS Console or Google Cloud console, with infrastructure-as-code tools such as Terraform, you can manage infrastructure in configuration files.

Infrastructure as Code has several benefits over manually managing infrastructure.
- Create, deploy, and manage infrastructure in a consitent way
- You can commit to source control and collaborate on infrastructure
- You can reuse and share configurations

Examples of infrastructure as code tools:
- Terraform
- Serverless Framework
- Cloud Formation

## What is Terraform
Terraform is HashiCorp's infrastructure as code tool. It uses the HashiCorp configuration language to allow devops engineers to write readable, declarative, reusable configurations for infrastructure. It also provids a command-line tool that provides a straight-forward workflow for updates.

Terraform has some advantages over other IaC options:
- You can use it to deploy to multiple cloud platforms and services.
- It used HashiCorp Configuration Language (HCL) which is easy to read, understand, and write.
- It has a built-in workflow.
- Provider specific definitions

## Terraform Use Cases
Terraform use cases are as varied as all devops projects.
- Create cloud networking environment
- Deploy web applications
- Declare data-pipelines
- Manage Security around infrastructure
- And many more...

## Example Code
```tf
resource "aws_instance" "test_server" {
  ami = "ami-0f19d220602031aed"
  instance_type = "t2.nano"

  key_name = "sshkeyname"

  tags = {
    name: "test server"
  }
}
```

## How it works
Either Terraform, or third-parties, write "providers" which map command-line tools from service providers to resources that can be used in Terraform configurations. Providers exist for AWS, Google Cloud, Azure, Heroku, Kubernetes, Digital Ocean, Terraform Cloud, and many more.

First the practitioner writes Terraform code. Then they plan and apply their changes. This uses the provider definitions to deploy the defined resources to the one or many clouds.

[Next: Basic Grammar](BASIC_GRAMMAR.md)
