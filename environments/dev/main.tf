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

  # General Config
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

  # General Config
  environment = var.environment

  # Network Config
  vpc_id                = module.vpc.vpc_id
  subnets_ids_data      = module.vpc.subnet_data_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

  # Security y Encrypted
  key_arn = module.kms_rds.key_arn

  # Engine Configuración
  engine_version  = var.engine_version
  database_name   = var.database_name
  master_username = var.master_username

  # Compute Configuration
  instance_count = var.instance_count
  instance_class = var.instance_class
}

module "alb" {
  source = "../../modules/alb"

  # General Config
  environment = var.environment

  # Network Config
  vpc_id                = module.vpc.vpc_id
  subnets_ids_public    = module.vpc.subnet_public_id
  subnets_cidrs_private = module.vpc.subnet_private_cidr

}

module "asg" {
  source = "../../modules/asg"

  # General Config
  environment = var.environment

  # Network Config
  vpc_id         = module.vpc.vpc_id
  subnet_private = module.vpc.subnet_private_id

  # ALB Integration
  arn_target_group      = module.alb.target_group_arn
  security_group_id_alb = [module.alb.security_group_id]

  # Aurora Integration
  security_group_id_aurora = [module.rds_aurora.security_group_id]

  # Compute Configuration
  instance_type        = var.instance_type
  instance_volume_size = var.instance_volume_size

  # Scaling Configuration
  asg_desired_capacity = var.asg_desired_capacity
  asg_min_size         = var.asg_min_size
  asg_max_size         = var.asg_max_size
}

module "config" {
  source = "../../modules/config"

  # General Config

  environment = var.environment

  # Retention and delivery policy
  log_retention_days = 90
  delivery_frequency = "TwentyFour_Hours"

  # Compliance rule
  config_rules = [
    {
      name       = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
      parameters = {}
    },
    {
      name = "RESTRICTED_INCOMING_TRAFFIC"
      parameters = {
        blockedPort1 = "22"
        blockedPort2 = "5432"
      }
    },
    {
      name       = "RDS_STORAGE_ENCRYPTED"
      parameters = {}
    },
    {
      name       = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
      parameters = {}
    },
  ]
}

module "guardduty" {
  source = "../../modules/guardduty"

  # General Config
  environment = var.environment

  # Frequency of Publication of Findings
  finding_publishing_frequency = "SIX_HOURS"

  # Additional Features
  s3_data_events         = false
  ebs_malware_protection = false
}

module "security_hub" {
  source = "../../modules/security-hub"

  # Standards Security
  standards_arn = [
    "arn:aws:securityhub:::standards/aws-foundational-security-best-practices/v/1.0.0",
  ]
}

module "notifications" {
  source = "../../modules/notifications"

  # General Config
  environment = var.environment

  # Notification Subscription
  email_sns = var.email_sns
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  # General Config
  environment = var.environment

  # Auto Scaling Group
  autoscaling_group_name = module.asg.autoscaling_group_name
  asg_cpu                = 80

  # Load Balancer
  lb_arn_suffix              = module.alb.lb_arn_suffix
  lb_target_group_arn_suffix = module.alb.lb_target_group_arn_suffix
  lb_5XX                     = 50

  # RDS
  rds_cluster_identifier = module.rds_aurora.rds_cluster_identifier
  rds_connections        = 100
  rds_storage_free       = 20

  # Notifications
  sns_topic_arn = module.notifications.sns_topic_arn
}

module "security_notifications" {
  source = "../../modules/security-notifications"

  # General Config
  environment = var.environment

  # Severity threshold
  minimum_severity = 4

  # Notifications
  sns_topic_arn = module.notifications.sns_topic_arn
}