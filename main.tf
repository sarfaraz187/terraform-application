terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

resource "aws_s3_bucket" "se2-terraform-bucket" {
  bucket = "se2-terraform-bucket"

  tags = {
    Name        = "My demo Bucket"
    Environment = "Dev"
  }
}