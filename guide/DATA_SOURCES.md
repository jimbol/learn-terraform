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

Lets use AWS's provider to find all the regions
