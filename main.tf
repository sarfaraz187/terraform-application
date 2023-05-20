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
  access_key = "AKIAQQEWPIF4QKPU37ML"
  secret_key = "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"
}

resource "aws_s3_bucket" "se2-terraform-bucket" {
  bucket = "se2-terraform-bucket"

  tags = {
    Name        = "My demo Bucket"
    Environment = "Dev"
  }
}