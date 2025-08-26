output "vpc_id" {
  value = aws_vpc.primary.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}