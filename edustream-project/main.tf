# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {
  state = "available"
}

# 1. CREATE THE VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "EduStream-VPC"
  }
}

# 2. CREATE SUBNETS
# We need 2 AZs for High Availability, and 3 tiers (Public, Web, Data)
# Total = 6 Subnets

# -- Public Subnets (for Load Balancer & NAT Gateway) --
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true 
  tags = {
    Name = "EduStream-Public-Subnet-A"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "EduStream-Public-Subnet-B"
  }
}

# -- Web Subnets (for EC2 Instances / Application) --
resource "aws_subnet" "web_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = false # Private subnets DO NOT get public IPs

  tags = {
    Name = "EduStream-Web-Subnet-A"
  }
}

resource "aws_subnet" "web_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "EduStream-Web-Subnet-B"
  }
}

# -- Data Subnets (for RDS Database) --
resource "aws_subnet" "data_a" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.20.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "EduStream-Data-Subnet-A"
  }
}

resource "aws_subnet" "data_b" {
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.21.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "EduStream-Data-Subnet-B"
  }
}

# 3. CREATE GATEWAYS

# -- Internet Gateway (for Public Subnets to access internet) --
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "EduStream-IGW"
  }
}

# -- NAT Gateways (for Private Subnets to access internet) --
# We need an Elastic IP for each NAT Gateway
resource "aws_eip" "nat_a" {
  domain = "vpc"
  tags = {
    Name = "EduStream-EIP-A"
  }
}

resource "aws_eip" "nat_b" {
  domain = "vpc"
  tags = {
    Name = "EduStream-EIP-B"
  }
}

resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id # NAT GW lives in a public subnet

  tags = {
    Name = "EduStream-NAT-GW-A"
  }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id # NAT GW lives in a public subnet

  tags = {
    Name = "EduStream-NAT-GW-B"
  }
  depends_on = [aws_internet_gateway.main]
}

# 4. CREATE ROUTE TABLES

# -- Public Route Table (sends internet traffic to IGW) --
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # "Anywhere"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "EduStream-Public-RT"
  }
}

# -- Web Route Tables (sends internet traffic to NAT GWs) --
resource "aws_route_table" "web_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "EduStream-Web-RT-A"
  }
}

resource "aws_route_table" "web_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "EduStream-Web-RT-B"
  }
}

# -- Data Route Tables (also send traffic to NAT GWs) --
resource "aws_route_table" "data_a" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }

  tags = {
    Name = "EduStream-Data-RT-A"
  }
}

resource "aws_route_table" "data_b" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }

  tags = {
    Name = "EduStream-Data-RT-B"
  }
}

# 5. ASSOCIATE ROUTE TABLES WITH SUBNETS
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "web_a" {
  subnet_id      = aws_subnet.web_a.id
  route_table_id = aws_route_table.web_a.id
}
resource "aws_route_table_association" "web_b" {
  subnet_id      = aws_subnet.web_b.id
  route_table_id = aws_route_table.web_b.id
}
resource "aws_route_table_association" "data_a" {
  subnet_id      = aws_subnet.data_a.id
  route_table_id = aws_route_table.data_a.id
}
resource "aws_route_table_association" "data_b" {
  subnet_id      = aws_subnet.data_b.id
  route_table_id = aws_route_table.data_b.id
}