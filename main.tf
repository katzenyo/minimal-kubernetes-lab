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
  profile = "kiplet-dev"
  

  default_tags {
    tags = {
      kube-training = "for kubernetes training"
    }
  }
}