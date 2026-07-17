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

resource "aws_iam_instance_profile" "kibana" {
  name = "kibana-profile"
  role = aws_iam_role.kibana.name
}

resource "aws_instance" "kibana" {
  ami                  = "ami-06fa3e561475dbbb4"
  instance_type        = "t4g.small"
  subnet_id            = aws_subnet.private.id
  iam_instance_profile = aws_iam_instance_profile.kibana.id
  vpc_security_group_ids = [
    aws_security_group.ec2_ssm_sg.id,
    aws_security_group.bastion_sg.id
  ]
  user_data = <<-EOF
    #!/bin/bash
    systemctl start sshd
    systemctl enable sshd

    TARGET_USER="ec2-user"
    USER_HOME="/home/$TARGET_USER"
    SSH_DIR="$USER_HOME/.ssh"

    mkdir -p "$SSH_DIR"

    REMOTE_PUB_HOST_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdy8jkIhN5Y76gMKCgWKJ6ps5aIY7lMg6xCqoLtR9KraOfSG4Rv6AnXgmWGbI7+3oDOnnC9xiIfNNIebNzypwV403BkieU7FdTbmP2btmlDm7WsV9FwQDk4iFGVXbITOD2ov+hAy2BJPOc8xgjdUkXYjeBW8HShG88KlKSEefGVYItthCbv0aqsqHT7/Y+/mc37XozYhVBeyU7xXwq45TbggrV8BReVTXAB11Zjgkwl4GAb96tiSpQUhYtOBMEgS8rTP4so/nz/YzDVwWtWGFZxEOSh48SEyRErHP8TV7yibqGOz/qLzc67OqLhM6K1JqETVoW3Ib44nmt82FOPVaJDrBfGhBgYe5J5JPb4TTE4dOuRySjB+K63NaeL+lv634rskZEG/DAPx7SZmawr5KbIbsOUJ84irSG4tHQK1KCZo88U3e3ZjDwpuqYkZk2Gjmc5CP8Y7gmdrnoeyoW86H8/8tnBtJjTUetotq37UYR2W+Ty16WAAQgqo5T3RdwllU= ec2-user@ip-10-0-2-31.us-east-2.compute.internal" 
    echo "$REMOTE_PUB_HOST_KEY" >> "$SSH_DIR/authorized_keys"

    # 4. Enforce strict permissions required by SSH
    chmod 700 "$SSH_DIR"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown -R "$TARGET_USER:$TARGET_USER" "$SSH_DIR"
  EOF

  tags = {
    Name    = "kibana"
    Service = "kibana"
  }
}
