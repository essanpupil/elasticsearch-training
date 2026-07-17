data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "terraform-state-803309190098"
    key    = "us-east-2/vpc/terraform.tfstate"
    region = "us-east-2"
  }
}
