terraform {
  backend "s3" {
    bucket  = "terraform-state-803309190098"
    key     = "us-east-2/vpc/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Owner     = "Ikhsan"
      ManagedBy = "Terraform"
    }
  }
}
