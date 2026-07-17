output "vpc_id" {
  value = aws_vpc.main.id
  type  = string
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public.id, aws_subnet.public_b.id]
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "data_subnet_id" {
  value = aws_subnet.data.id
}
