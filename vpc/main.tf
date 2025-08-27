resource "aws_vpc" "primary" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.primary.id
  cidr_block = var.private_cidr
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw-primary" {
  vpc_id = aws_vpc.primary.id
}

### Route Tables

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0" # full public ingress
    gateway_id = aws_internet_gateway.igw-primary.id
  }

  tags = {
    Name = "public-route-to-igw"
  }
}

resource "aws_route_table_association" "public_route" {
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.private.id
}