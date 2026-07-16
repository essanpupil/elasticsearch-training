data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"] # Official fck-nat AWS account ID

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-ebs"]
  }
}

data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Official fck-nat AWS account ID

  filter {
    name   = "name"
    values = ["debian-13-arm64-*-*"]
  }
}
