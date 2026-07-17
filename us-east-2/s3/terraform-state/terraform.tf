terraform {
  backend "s3" {
    bucket         = "terraform-state-803309190098"
    key            = "us-east-2/s3/terraform-state"
    region         = "us-east-2"
    encrypt        = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}
