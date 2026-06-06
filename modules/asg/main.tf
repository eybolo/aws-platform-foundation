data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

data "aws_availability_zones" "available" {}

resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Security group controlling inbound and outbound traffic to the ASG."
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.security_group_id_alb
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.security_group_id_aurora
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_iam_role" "this" {
  name = local.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = local.iam_instace_profile_name
  role = aws_iam_role.this.name
}

resource "aws_launch_template" "this" {
  name = local.launch_template_name
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = var.instance_volume_size
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  image_id = data.aws_ssm_parameter.amazon_linux_2023.value

  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.this.id]

  tags = local.common_tags
}

resource "aws_autoscaling_group" "this" {
  name                = local.autoscaling_group_name
  vpc_zone_identifier = var.subnet_private
  desired_capacity    = var.asg_desired_capacity
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  target_group_arns   = [var.arn_target_group]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.this.id
      }
    }
  }
  dynamic "tag" {
    for_each = local.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}
