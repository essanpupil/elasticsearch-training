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

resource "aws_iam_instance_profile" "elasticsearch" {
  name = "es-nodes-profile"
  role = aws_iam_role.elasticsearch.name
}

resource "aws_instance" "elasticsearch" {
  count                  = 3
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.data.id
  iam_instance_profile = aws_iam_instance_profile.elasticsearch.id

  tags = {
    Name = "es-node-${count.index + 1}"
    Service = "elasticsearch"
  }
}
