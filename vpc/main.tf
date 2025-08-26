resource "aws_vpc" "primary" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.primary.id
  cidr_block = var.private_cidr
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "igw-primary" {
  vpc_id = aws_vpc.primary.id
}