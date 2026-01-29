variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


variable "bucket_prefix" {
  description = "Prefix for the S3 bucket name."
  type        = string
  default     = "my-static-website-"
}
variable "index_file" {
  description = "The name of the main HTML file"
  type        = string
  default     = "index.html"
}