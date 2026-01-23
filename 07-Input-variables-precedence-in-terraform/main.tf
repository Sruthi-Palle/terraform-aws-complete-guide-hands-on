# main.tf

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region # Use a variable for region
}

# Define an AWS EC2 instance resource
resource "aws_instance" "my_parameterized_ec2" {
  ami           = var.instance_ami_id
  instance_type = var.instance_type

  tags = {
    Name = "ParameterizedEC2-${var.environment}"
    Environment = var.environment
  }
}

# Output the public IP of the EC2 instance
output "ec2_public_ip_parameterized" {
  value       = aws_instance.my_parameterized_ec2.public_ip
  description = "The public IP address of the parameterized EC2 instance."
}