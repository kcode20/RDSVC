# Define a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = "main-vpc"
  }
}

# Define a public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    "Name" = "Web Public Subnet"
  }
}

# Define a private subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1e"

  tags = {
    "Name" = "Private Subnet 1"
  }
}

# Define a private subnet
resource "aws_subnet" "private-subnet-2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1d"

  tags = {
    "Name" = "Private Subnet 2"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "VPC IGW"
  }
}

# Define the route table for the public subnet
resource "aws_route_table" "web-public-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Subnet RT"
  }
}

# Assign the route table to the public subnet
resource "aws_route_table_association" "web-public-rt" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.web-public-rt.id
}
