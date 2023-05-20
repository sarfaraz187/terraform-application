terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "eu-north-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "se2-terraform-bucket" {
  bucket = "se2-terraform-bucket"

  tags = {
    Name        = "My demo Bucket updated"
    Environment = "Dev"
  }
}