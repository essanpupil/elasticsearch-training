output "vpc_id" {
    value = aws_vpc.main.id
    type = string
}

output "public_subnet_id" {
    value = aws_subnet.public.id
}

output "private_subnet_id" {
    value = aws_subnet.private.id
}

output "data_subnet_id" {
    value = aws_subnet.data.id
}
