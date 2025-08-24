variable "us_aws_region" {
  description = "The default AWS region for resources"
  type = string
  default = "us-east-1"
}

### EC2 vars

# t3.small vars

variable "small_instance_type" {
  description = "Small instance type"
  type = string
  default = "t3.small"
}

# t3.micro vars

variable "micro_instance_type" {
  description = "Micro instance"
  type = string
  default = "t3.micro"
}

### Networking vars

variable "vpc_cidr" {
  description = "Primary VPC CIDR block"
  type = string
  default = "16.0.0.0/16"
}

variable "public_cidr" {
  description = "Public subnet"
  type = string
  default = "16.0.1.0/24"
}

variable "private_cidr" {
  description = "Private subnet"
  type = string
  default = "16.0.2.0/24"
}