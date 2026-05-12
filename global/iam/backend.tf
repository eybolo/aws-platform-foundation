terraform {
  backend "s3" {
    key    = "global/iam/terraform.tfstate"
    encrypt = true
  }
}
