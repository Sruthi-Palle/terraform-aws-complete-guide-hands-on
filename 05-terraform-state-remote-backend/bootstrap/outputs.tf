#provide code for output of bucket NAME

output "bucket_name" {
  description = "The name of the S3 bucket created for storing Terraform state."
  value       = aws_s3_bucket.state_bucket.id
}

