terraform {
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

# Resource block for AWS S3
resource "aws_s3_bucket" "se2-terraform-bucket" { // create se2-demo-bucket
  bucket = "se2-terraform-bucket"

  tags = {
    Name        = "Bucket tag name"
    Environment = "Dev"
  }
}

# Origin access identity (OAI) Key name
locals {
  s3_origin_id = "terraform-dev"
}

resource "aws_cloudfront_origin_access_identity" "my_origin_access_identity" {
  comment = "terraform-oai-key"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    # OAI domain name the source which is S3 bucket.
    domain_name = aws_s3_bucket.se2-terraform-bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    # Using the orgin access created identity from resource
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my_origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true # The distribution is enabled to accept end user requests
  is_ipv6_enabled     = true # Whether the IPv6 is enabled for the distribution
  comment             = "Dev environment"
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

  price_class = "PriceClass_All" # Price class of destribution
  restrictions {
    geo_restriction {
      restriction_type = "none" # Method to restrict distribution of your content by country
      locations        = [] # ISO 3166-1-alpha-2 codes
    }
  }

  tags = {
    Environment = "dev"
  }

  viewer_certificate {
    cloudfront_default_certificate = true # SSL configuration for HTTPS to request your objects
  }

  # Error page and route to redirect to
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }
}

# A data block requests that Terraform read from a given data source and export a given local name
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

# We get the bucket ID from the resource that we created above
resource "aws_s3_bucket_policy" "se2-terraform-bucket" {
  bucket = aws_s3_bucket.se2-terraform-bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json # Policy created in data module is passed in here
}

# resource "aws_s3_bucket_acl" "se2-se2-terraform-bucket" {
#   bucket = aws_s3_bucket.se2-se2-terraform-bucket.id
#   acl    = "private"
# }

# backend "remote" {
#   organization = "onespace"

#   workspaces {
#     name = "terraform-application"
#   }
# }