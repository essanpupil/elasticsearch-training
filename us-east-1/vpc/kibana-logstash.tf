data "aws_iam_policy_document" "kibana" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "kibana" {
  name               = "kibana-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.kibana.json
}

resource "aws_iam_role_policy_attachment" "kibana_ssm_attach" {
  role       = aws_iam_role.kibana.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "kibana" {
  name = "kibana-profile"
  role = aws_iam_role.kibana.name
}

resource "aws_instance" "kibana" {
  ami                  = "ami-0c7217cdde317cfec"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.kibana.id
  vpc_security_group_ids = [
    aws_security_group.ec2_ssm_sg.id
  ]
  tags = {
    Name    = "kibana"
    Service = "kibana"
  }
}
