# Use data source to pull info from bootstrap if needed
data "terraform_remote_state" "bootstrap" {
  backend = "s3"
  config = {
    bucket = "my-unique-company-state-2026"
    key    = "bootstrap/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}