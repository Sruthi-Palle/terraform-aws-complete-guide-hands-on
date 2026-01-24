# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources."
  type        = string
  default     = "us-east-1"
}

variable "instance_ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
  default     = "ami-053b0d53c27927904" # Default for us-east-1 Amazon Linux 2
}

variable "instance_type" {
  description = "The instance type for the EC2 instance."
  type        = string
  default     = "t2.micro"
}

variable "environment" {
  description = "The environment tag for the resources."
  type        = string
  default     = "Development"
}