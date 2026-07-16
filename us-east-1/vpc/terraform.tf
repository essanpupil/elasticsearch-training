terraform {
  # backend "s3" {
  #   bucket         = "terraform-state-257353114610"
  #   key            = "us-east-1/vpc/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
