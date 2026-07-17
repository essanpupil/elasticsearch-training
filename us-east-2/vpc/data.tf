data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"] # Official fck-nat AWS account ID

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-ebs"]
  }
}

