data "aws_iam_policy_document" "elasticsearch" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "elasticsearch" {
  name               = "es-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.elasticsearch.json
}

resource "aws_iam_role_policy_attachment" "elasticsearch_ssm_attach" {
  role       = aws_iam_role.elasticsearch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "elasticsearch" {
  name = "es-nodes-profile"
  role = aws_iam_role.elasticsearch.name
}

resource "aws_instance" "elasticsearch" {
  count                = 3
  ami                  = data.aws_ami.debian.id
  instance_type        = "t4g.micro"
  subnet_id            = aws_subnet.data.id
  iam_instance_profile = aws_iam_instance_profile.elasticsearch.id
  vpc_security_group_ids = [
    aws_security_group.ec2_ssm_sg.id
  ]

  tags = {
    Name    = "es-node-${count.index + 1}"
    Service = "elasticsearch"
  }
}
