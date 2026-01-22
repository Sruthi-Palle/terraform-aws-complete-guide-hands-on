# 01-project-app/backend.tf

terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "my-unique-company-state-2026" # Must match bootstrap name
    key          = "project-app/terraform.tfstate" # Unique path for this app
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                          # Modern S3 Native Locking
  }
}