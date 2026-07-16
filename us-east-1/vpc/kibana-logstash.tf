resource "aws_instance" "kibana" {
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private.id

  tags = {
    Name = "kibana"
    Service = "kibana"
  }
}
