# 1. Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true #Guarantees the newest release is selected.
  owners      = ["amazon"] #Ensures the image is an official Amazon-provided image.

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"] #Uses a wildcard to match the naming convention of the OS.
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"] #Restricts the search to Hardware Virtual Machine images.
  }
}

# 2. Reference an existing Shared VPC by its "Name" tag
data "aws_vpc" "shared_vpc" {
  filter {
    name   = "tag:Name"
    values = ["Production-VPC"] # Matches the tag in your AWS Console
  }
}

# 3. Reference an existing Subnet within that VPC
data "aws_subnet" "selected_subnet" {
  filter {
    name   = "tag:Name"
    values = ["Public-Subnet-A"]
  }
  
  # Optional: Ensure the subnet belongs to the VPC found above
  vpc_id = data.aws_vpc.shared_vpc.id
}

# 4. Provision the EC2 Instance using the retrieved Data
resource "aws_instance" "web_server" {
  # Dynamically uses the ID from the AMI data source
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"

  # Dynamically uses the ID from the Subnet data source
  subnet_id     = data.aws_subnet.selected_subnet.id

  tags = {
    Name = "App-Server-Dynamic"
  }
}

# Output the IDs to verify what Terraform found
output "resolved_ami_id" {
  value = data.aws_ami.amazon_linux_2.id
}

output "resolved_subnet_id" {
  value = data.aws_subnet.selected_subnet.id
}