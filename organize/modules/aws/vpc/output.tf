output "vpc_id" {
  description = "The id of our vpc"
  value = module.vpc_module.vpc_id
}

output "public_subnet_id" {
  description = "id of our public subnet"
  value = module.vpc_module.public_subnets[0]
}
