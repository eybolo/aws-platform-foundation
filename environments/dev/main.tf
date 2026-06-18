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

  # Configuracion General
  environment = var.environment

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
}

module "rds_aurora" {
  source = "../../modules/rds-aurora"

  # Configuracion General
  environment = var.environment

  # Configuración de Red
  vpc_id                = module.vpc.vpc_id
  subnets_ids_data      = module.vpc.subnet_data_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

  # Seguridad y Cifrado
  key_arn = module.kms_rds.key_arn

  # Configuración del Motor
  engine_version  = var.engine_version
  database_name   = var.database_name
  master_username = var.master_username

  # Dimensionamiento del Cómputo
  instance_count = var.instance_count
  instance_class = var.instance_class
}

module "alb" {
  source = "../../modules/alb"

  # Configuracion General
  environment = var.environment

  # Configuración de Red
  vpc_id                = module.vpc.vpc_id
  subnets_ids_public    = module.vpc.subnet_public_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

  # Seguridad y Certificados
  certificate_arn = var.certificate_arn
}

module "asg" {
  source = "../../modules/asg"

  # Configuracion General
  environment = var.environment

  # Configuración de Red
  vpc_id         = module.vpc.vpc_id
  subnet_private = module.vpc.subnet_private_id

  # Integración con ALB
  arn_target_group      = module.alb.target_group_arn
  security_group_id_alb = [module.alb.security_group_id]

  # Integración con Aurora
  security_group_id_aurora = [module.rds_aurora.security_group_id]

  # Configuración de Cómputo
  instance_type        = var.instance_type
  instance_volume_size = var.instance_volume_size

  # Configuración de Escalado
  asg_desired_capacity = var.asg_desired_capacity
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
}
