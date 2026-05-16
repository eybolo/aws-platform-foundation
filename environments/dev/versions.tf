terraform {
  required_version = "~> 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = local.common_tags
  }
}