output "vpc_id" {
  description = "The ID of the main VPC"
  value       = module.vpc.vpc_id
}

output "subnet_public_id" {
  description = "List of IDs for all created public subnets"
  value       = module.vpc.subnet_public_id
}

output "subnet_private_id" {
  description = "List of IDs for all created private subnets"
  value       = module.vpc.subnet_private_id
}

output "subnet_data_id" {
  description = "List of IDs for all created data subnets"
  value       = module.vpc.subnet_data_id
}