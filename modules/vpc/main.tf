resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = local.common_tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = local.common_tags
}

resource "aws_subnet" "subnet_public" {
  vpc_id= aws_vpc.main.id 
  count = length (var.subnet_public)
  cidr_block = var.subnet_public[count.index]
  map_public_ip_on_launch = true

  availability_zone = var.availability_zones[count.index]
  tags = merge(
    local.common_tags,
    {
      "Name" = "public-subnet-${count.index}"
    }
  )

}

resource "aws_subnet" "subnet_private" {
  vpc_id= aws_vpc.main.id 
  count = length (var.subnet_private)
  cidr_block = var.subnet_private[count.index]

  availability_zone = var.availability_zones[count.index]
  tags = merge(
    local.common_tags,
    {
      "Name" = "private-subnet-${count.index}"
    }
  )

}

resource "aws_subnet" "subnet_data" {
  vpc_id= aws_vpc.main.id 
  count = length (var.subnet_data)
  cidr_block = var.subnet_data[count.index]

  availability_zone = var.availability_zones[count.index]
  tags = merge(
    local.common_tags,
    {
      "Name" = "data-subnet-${count.index}"
    }
  )
  
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags = local.common_tags

}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.subnet_public[0].id
  depends_on = [aws_internet_gateway.gw]
  tags = local.common_tags
  
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = local.common_tags

}

resource "aws_route_table" "rt_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
    }

  tags = local.common_tags

}

resource "aws_route_table" "rt_data" {
  vpc_id = aws_vpc.main.id

  tags = local.common_tags

}

resource "aws_route_table_association" "rt_assoc_public" {
  route_table_id = aws_route_table.rt_public.id
  count = length(var.subnet_public)
  subnet_id = aws_subnet.subnet_public[count.index].id
}

resource "aws_route_table_association" "rt_assoc_private" {
  route_table_id = aws_route_table.rt_private.id
  count = length(var.subnet_private)
  subnet_id = aws_subnet.subnet_private[count.index].id
}

resource "aws_route_table_association" "rt_assoc_data" {
  route_table_id = aws_route_table.rt_data.id
  count = length(var.subnet_data)
  subnet_id = aws_subnet.subnet_data[count.index].id
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn = aws_iam_role.vpc_flow_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  traffic_type = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs"{
  name = "/aws/vpc/flow-logs-${var.environment}"
  #kms_key_id  hacerlo despues cuando se crea el modulo KMS
  tags = local.common_tags
}

resource "aws_iam_role" "vpc_flow_role" {
  name = "vpc-flow-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
  
}

resource "aws_iam_role_policy" "vpc_flow_policy" {
  name = "vpc-flow-${var.environment}"
  role = aws_iam_role.vpc_flow_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}