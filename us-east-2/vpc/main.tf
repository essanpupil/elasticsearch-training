resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Observability Cluster"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-2b"

  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "data" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "data-subnet"
  }
}

resource "aws_security_group" "nat_sg" {
  name        = "nat-instance-sg"
  description = "Allow private subnet traffic to egress to the internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.private.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-instance-sg"
  }
}

resource "aws_security_group" "nat_sg_data" {
  name        = "data-nat-instance-sg"
  description = "Allow private subnet traffic to egress to the private subnet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.data.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "data-nat-instance-sg"
  }
}

resource "aws_instance" "nat" {
  ami           = data.aws_ami.fck_nat.id
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  source_dest_check      = false

  tags = {
    Name = "nat-instance"
  }
}

resource "aws_instance" "nat_data" {
  ami           = data.aws_ami.fck_nat.id
  instance_type = "t4g.nano"
  subnet_id     = aws_subnet.private.id

  vpc_security_group_ids = [aws_security_group.nat_sg_data.id]
  source_dest_check      = false

  tags = {
    Name = "data-nat-instance"
  }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat.primary_network_interface_id
  }

  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id


  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_data.primary_network_interface_id
  }

  tags = {
    Name = "data-route-table"
  }
}

resource "aws_route_table_association" "data" {
  subnet_id      = aws_subnet.data.id
  route_table_id = aws_route_table.data.id
}

resource "aws_security_group" "ec2_ssm_sg" {
  name        = "ec2-ssm-security-group"
  description = "Allow outbound HTTPS traffic for SSM"
  vpc_id      = aws_vpc.main.id

  # No inbound rules are needed for SSM

  egress {
    description = "Allow HTTPS outbound to SSM endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
