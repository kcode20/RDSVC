terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

# Define AWS as our provider
provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# Define a VPC
resource "aws_vpc" "main"{
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    "Name" = "main-vpc"
  }
}

# Define a public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  tags{
    "Name" = "Web Public Subnet"
  }
}

# Define a private subnet
resource "aws_subnet" "public-subnet" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = ""
  availability_zone = "us-east-1c"
  tags{
    "Name" = "Database Private Subnet"
  }
}

# Define the internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "VPC IGW"
  }
}


# Creates an EC2 instance
resource "aws_instance" "rdsvc-ec2" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
}
