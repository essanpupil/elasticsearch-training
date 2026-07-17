resource "aws_security_group" "bastion_sg" {
  name        = "bastion-public-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "bastion-security-group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_self" {
  security_group_id = aws_security_group.bastion_sg.id
  description       = "Allow SSH from same security group across any subnet"

  referenced_security_group_id = aws_security_group.bastion_sg.id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.bastion_sg.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

data "aws_iam_policy_document" "bastion" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "bastion" {
  name               = "bastion-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.bastion.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_attach" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
  ami                    = "ami-06fa3e561475dbbb4"
  instance_type          = "t4g.micro"
  subnet_id              = data.terraform_remote_state.vpc.outputs.private_subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.id

  tags = {
    Name = "bastion-host"
  }
}
