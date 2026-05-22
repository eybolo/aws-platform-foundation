data "aws_availability_zones" "available" {}

resource "aws_db_subnet_group" "this" {
  name       = local.db_subnet_group_name
  subnet_ids = var.subnets_ids_data

  tags = local.common_tags
}

resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Security group controlling inbound and outbound traffic to the Aurora PostgreSQL cluster."
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.subnets_cidrs_private
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "random_password" "master_password_aurora" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "this" {
  name       = local.secretsmanager_secret_name
  kms_key_id = var.key_arn

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    host     = aws_rds_cluster.this.endpoint
    port     = aws_rds_cluster.this.port
    dbname   = aws_rds_cluster.this.database_name
    username = aws_rds_cluster.this.master_username
    password = random_password.master_password_aurora.result
  })
}

resource "aws_rds_cluster" "this" {
  cluster_identifier      = local.rds_cluster_name
  engine                  = "aurora-postgresql"
  engine_version          = var.engine_version
  availability_zones      = slice(data.aws_availability_zones.available.names, 0, 2)
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = random_password.master_password_aurora.result
  kms_key_id              = var.key_arn
  storage_encrypted       = true
  vpc_security_group_ids  = [aws_security_group.this.id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "this" {
  count              = var.instance_count
  identifier         = "${local.rds_cluster_name}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.instance_class
  engine_version     = var.engine_version
  engine             = "aurora-postgresql"

  tags = local.common_tags
}

