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

resource "aws_security_group" "this" {
  name        = "es-nodes-sg"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "es-nodes-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "elasticsearch_access" {
  security_group_id = aws_security_group.this.id
  referenced_security_group_id = data.terraform_remote_state.kibana.outputs.security_group_id
  from_port   = 9200
  ip_protocol = "tcp"
  to_port     = 9200
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_from_bastion" {
  security_group_id = aws_security_group.this.id
  referenced_security_group_id = data.terraform_remote_state.bastion.outputs.security_group_id

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.this.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
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
  count                = 3
  ami                  = "ami-0e68dc81dc36750a1"
  instance_type        = "t3.small"
  subnet_id            = data.terraform_remote_state.vpc.outputs.data_subnet_id
  iam_instance_profile = aws_iam_instance_profile.elasticsearch.id
  vpc_security_group_ids = [
    aws_security_group.this.id,
  ]
  user_data = <<-EOF
    #!/bin/bash
    systemctl start sshd
    systemctl enable sshd

    TARGET_USER="ec2-user"
    USER_HOME="/home/$TARGET_USER"
    SSH_DIR="$USER_HOME/.ssh"

    mkdir -p "$SSH_DIR"

    REMOTE_PUB_HOST_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2uyBm+4okNZMf5dsZWZd9hzTmqS15xL8xVwarSxuA2G08KxVeRDzBJTDcHAin70BNaYAfP0+p/7u1VejmaQ3nwoWwEqwpsbb4VlFmxi3LeJqGupVbN+Hoj7MqZCZAP1mAUJKMqayJuBkGe7b9cJcPlvHD6sgM6mfiA/BJwil4UIWAd2imhhqe7J9x6/54+pp9HvXh0SPqYgeLZHw4gbN/vTiEl3DmMSgKQxaOTqSxsb/5PXsaq60swGa8ZR2tBrWQ3ZEcuUYAkHwglbrVcX3k99ntAKDIX+2PZytFVYP6v2nkPqQETeIX7oP7dri46ohHQfEunIjjPGorOGkFSXAMW90maHk3zLoqVkgxDzmfrtffmciB1utRwG2rFT2ajTPUyZnx09JayFopYtn+uY4HHjwtkQn0far4yPxJlnhO7mI8iwHQrL4I8/mn37QL9+ZUdbYTg8XnquwRKBljoxOeSJ6DRqh7nAalYuzRzUZz7x66i+sF80FJlkh4aVaRJS8= ec2-user@ip-10-0-2-179.us-east-2.compute.internal" 
    echo "$REMOTE_PUB_HOST_KEY" >> "$SSH_DIR/authorized_keys"

    # 4. Enforce strict permissions required by SSH
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"
  EOF

  tags = {
    Name    = "es-node-${count.index + 1}"
    Service = "elasticsearch"
  }
}
