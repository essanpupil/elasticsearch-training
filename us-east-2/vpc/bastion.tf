resource "aws_security_group" "bastion_sg" {
  name        = "bastion-public-sg"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-security-group"
  }
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
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.id

  tags = {
    Name = "bastion-host"
  }
}
