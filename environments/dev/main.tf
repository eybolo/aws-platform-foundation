module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr           = var.vpc_cidr
  subnet_public      = var.subnet_public
  subnet_private     = var.subnet_private
  subnet_data        = var.subnet_data
  availability_zones = var.availability_zones
  environment        = var.environment
}

module "kms_rds" {
  source = "../../modules/kms"

  service_principals = {
    "rds.amazonaws.com" = {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:CreateGrant"
      ]
    }
  }
  service_name = "rds"
  environment  = var.environment
}

module "kms_s3" {
  source = "../../modules/kms"

  service_principals = {
    "s3.amazonaws.com" = {
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ]
    }
  }
  service_name = "s3"
  environment  = var.environment
}

module "kms_ebs" {
  source = "../../modules/kms"

  service_principals = {
    "ec2.amazonaws.com" = {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:CreateGrant"
      ]
    }
  }
  service_name = "ebs"
  environment  = var.environment
}