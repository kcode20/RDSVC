/*
This file creates the webserver that lives in the public subnet.
It defines the security group and EC2 instance.
*/

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
