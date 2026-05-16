module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr = var.vpc_cidr
  subnet_public = var.subnet_public
  subnet_private = var.subnet_private
  subnet_data = var.subnet_data
  availability_zones = var.availability_zones
  environment = var.environment
}