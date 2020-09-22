terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "rdsvc-ec2" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
}
