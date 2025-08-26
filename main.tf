terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=6.7.0"
    }
  }
}

provider "aws" {
  region = var.us_aws_region
  profile = "admin"
  

  default_tags {
    tags = {
      kube-training = "for kubernetes training"
    }
  }
}

module "vpc" {
  source = "./vpc/"
  vpc_cidr = var.vpc_cidr
  private_cidr = var.private_cidr
}

module "compute" {
  source = "./compute/"
  vpc_id = module.vpc.vpc_id
  private_subnet_id = module.vpc.private_subnet_id
}