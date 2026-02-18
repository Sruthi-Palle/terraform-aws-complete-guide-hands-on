# VPC Module - Main Configuration

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  }
}

# Private Subnets for RDS (requires at least 2 AZs)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "${var.project_name}-private-subnet-1"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = "${var.aws_region}b"

  tags = {
    Name        = "${var.project_name}-private-subnet-2"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# --- NAT GATEWAY RESOURCES ---

# 1. Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main] # Best practice to ensure IGW exists first

  tags = {
    Name        = "${var.project_name}-nat-eip"
    Environment = var.environment
  }
}

# 2. NAT Gateway
# Placed in the Public Subnet so it has a path to the Internet Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name        = "${var.project_name}-nat-gw"
    Environment = var.environment
  }

  # To ensure proper ordering, it is recommended to depend on the IGW
  depends_on = [aws_internet_gateway.main]
}

# --- PRIVATE ROUTING ---

# 3. Private Route Table - directs your private subnets' outbound traffic to that gateway.
/* One-Way Traffic: By adding the 0.0.0.0/0 route pointing to the nat_gateway_id, your RDS instances or private servers 
can now download patches or reach APIs, but the public internet still cannot initiate a connection directly to them. */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-private-rt"
    Environment = var.environment
  }
}

# 4. Route Table Associations for Private Subnets
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}