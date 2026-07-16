resource "aws_instance" "elasticsearch" {
  count                  = 3
  ami                    = "ami-0c7217cdde317cfec"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.data.id

  tags = {
    Name = "es-node-${count.index + 1}"
  }
}
