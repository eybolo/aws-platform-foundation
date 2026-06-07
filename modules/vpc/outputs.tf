output "vpc_id" {
  description = "The ID of the main VPC"
  value       = aws_vpc.main.id
}

output "subnet_public_id" {
  description = "List of IDs for all created public subnets"
  value       = aws_subnet.subnet_public[*].id
}

output "subnet_private_id" {
  description = "List of IDs for all created private subnets"
  value       = aws_subnet.subnet_private[*].id
}

output "subnet_data_id" {
  description = "List of IDs for all created data subnets"
  value       = aws_subnet.subnet_data[*].id
}

output "subnet_private_cidr" {
 description = "List of CIDRs for all created private subnets" 
 value = aws_subnet.subnet_private.cidr_block 
}