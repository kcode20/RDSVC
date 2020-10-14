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
