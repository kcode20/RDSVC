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

# Define the security group for web server
resource "aws_security_group" "sg-web" {
  name        = "sg_web_server"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Web Server SG"
  }
}

# Define the security group for private subnet
resource "aws_security_group" "sg-db" {
  name        = "sg_db"
  description = "Allow traffic from public subnet"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Database SG"
  }
}

# Creates an EC2 instance in the public subnet
resource "aws_instance" "rdsvc-ec2" {
  ami           = "ami-00514a528eadbc95b" # Amazon Linux AMI
  instance_type = "t2.micro"
  key_name      = "rdsvc-ec2-keypair"

  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.sg-web.id]
  associate_public_ip_address = true
  user_data                   = file("userdata.sh")

  tags = {
    Name = "RDSVC EC2"
  }
}

# Create an RDS DB subnet group
resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]

  tags = {
    Name = "DB Subnet Group"
  }
}

# Create an RDS instance in the private subnet
resource "aws_db_instance" "mysql-db" {
  allocated_storage      = 5
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "mysqldb"
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.sg-db.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

# Create an S3 bucket
resource "aws_s3_bucket" "rdsvc-db-backups" {
  bucket = "rdsvc-db-backups"
  acl    = "private"

  tags = {
    Name = "Database Backups"
  }
}

# Create Role for Lambda Function 
resource "aws_iam_role" "lambda-role" {
  name               = "rdsvc-lambda-role"
  assume_role_policy = <<EOF
{
"Version": "2012-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": "lambda.amazonaws.com"
},
"Effect": "Allow",
"Sid": ""
}
]
}
EOF

  tags = {
    Name = "rdsvc-lambda-role"
  }
}

# Create IAM Policy
resource "aws_iam_policy" "rdsvc-lambda-policy" {
  name        = "rdsvc-lambda-policy"
  description = "A policy for the rdsvc lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:*", 
        "rds:*",
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda-role-policy-attachment" {
  policy_arn = aws_iam_policy.rdsvc-lambda-policy.arn
  role       = aws_iam_role.lambda-role.name
}

# Create Lambda Function
resource "aws_lambda_function" "rdsvc-lambda-function" {
  function_name = "rdsvc-lambda-function"
  filename      = "rdsvc-lambda.zip"
  handler       = "rdsvc-lambda.lambda.create_backup"
  role          = aws_iam_role.lambda-role.arn
  runtime       = "python3.7"
  timeout       = 100

  environment {
    variables = {
      MYSQL_DB   = aws_db_instance.mysql-db.name
      MYSQL_HOST = aws_db_instance.mysql-db.endpoint
      MYSQL_PORT = aws_db_instance.mysql-db.port
      MYSQL_USER = aws_db_instance.mysql-db.username
      MYSQL_PASS = var.db_password
      S3_BUCKET  = aws_s3_bucket.rdsvc-db-backups.id
    }
  }

  vpc_config {
    security_group_ids = [aws_security_group.sg-db.id]
    subnet_ids         = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]
  }

  tags = {
    Name = "rdsvc-lambda-function"
  }
}

# Create VPC Endpoint
resource "aws_vpc_endpoint" "saints-xctf-s3-vpc-endpoint" {
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private-subnet-1.id, aws_subnet.private-subnet-2.id]


  route_table_ids = [aws_route_table.web-public-rt.id]
}
