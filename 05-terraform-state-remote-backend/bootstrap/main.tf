# 00-bootstrap/main.tf
terraform {
  required_version = ">= 1.10.0" # Required for Native S3 Locking (use_lockfile)
  
  # INITIAL RUN: Comment out the backend block below.
  # AFTER STEP 1: Uncomment this and run 'terraform init -migrate-state'
  # backend "s3" {
  #   bucket       = "my-unique-company-state-2026"
  #   key          = "bootstrap/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true 
  # }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "my-unique-company-state-2026" # GLOBAL UNIQUE NAME
  
  lifecycle {
    prevent_destroy = true # Safety first!
  }
}

resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sec" {
  bucket = aws_s3_bucket.state_bucket.id
  rule { apply_server_side_encryption_by_default { sse_algorithm = "AES256" } }
}

# 1.10+ Native Locking: This creates a marker file to support locking
# In 2026, we don't need DynamoDB unless your compliance team insists.