terraform {

  # backend "remote" {
  #   organization = "onespace"

  #   workspaces {
  #     name = "terraform-application"
  #   }
  # }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region     = "eu-north-1"
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

# resource "aws_s3_bucket_acl" "se2-terraform-bucket" {
#   bucket = aws_s3_bucket.se2-terraform-bucket.id
#   acl    = "private"
# }

locals {
  s3_origin_id = "terraform-dev"
}

resource "aws_cloudfront_origin_access_identity" "my_origin_access_identity" {
  comment = "Some comment"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.se2-terraform-bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Some comment"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  tags = {
    Environment = "dev"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.se2-terraform-bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.my_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "se2-terraform-bucket" {
  bucket = aws_s3_bucket.se2-terraform-bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}