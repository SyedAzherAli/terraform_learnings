provider "aws" {
  region = "ap-south-1"
}
resource "aws_s3_bucket" "state_bucket" {
  bucket = ""       // Add unique bucket name

  # Prevent accidental deletion of this S3 bucket, comment these block to actual delete s3 bucket 
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_versioning" "VC_enable" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_server_side_encription_enable" {
  bucket = aws_s3_bucket.state_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.state_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# DynamoDB for locking with Terraform
resource "aws_dynamodb_table" "state_lock" {
  name         = ""                       // Add dynomodb table name
  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }
}


