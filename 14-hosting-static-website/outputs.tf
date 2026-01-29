output "website_url" {
  description = "The URL of the website"
  value       = "https://${aws_cloudfront_distribution.cdn.domain_name}"
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket"
  value       = aws_s3_bucket.website_bucket.bucket
}