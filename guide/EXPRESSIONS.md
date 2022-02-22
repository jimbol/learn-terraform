# Expressions
## Types
- `strings`: `"hi there"`
- `number`: `5`, `10002`
- `bool`: `true` or `false`
- `list`: `["us-east-1", "us-east-2"]`
- `map`: `{ region = "us-east-1", project_id = "proj-123456" }`

### Using types in variables
Types can all be used in variables under the type argument.

```tf
variable "env" {
  description = "Environment name"
  type = string
}
```
```tf
variable "subnet_cidr_blocks" {
  description = "CIDR blocks"
  type = list(string)
}
```
```tf
variable "subnet_cidr_blocks_map" {
  description = "CIDR blocks"
  type = map({
    private_cidrs = list(string),
    public_cidrs = list(string),
  })
}
```

## Operators
Terraform uses standard operators that you're probably familiar with.

- Mathematical Operators: `+ - * / %`
- Equality Operators: `x == y`, `x != y`
- Comparison Operators: `x < y`, `x >= y`
- Logical Operators: `x || y`, `x && y`

## Common Expressions
- Template Strings: `"Hi ${var.name}"`
- References: `module.vpc.subnet_id`
- Function Calls: `min(5, 100, 0.4)`, `trim(" Hello    ")`, find functions here: https://www.terraform.io/language/functions
- Conditionals: `var.boolValue ? x.id : y.id`

## Working with lists
- Loops: `[for myStr in var.list : upper(trim(myStr))]` returns list with trimmed, uppercase strings
- Splats: `var.list[*].id` returns a list of ids on each map in `var.list`

[Next: Meta-Arguments](META_ARGUMENTS.md)
