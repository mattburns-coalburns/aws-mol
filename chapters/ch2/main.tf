# Provider Block
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.8.0"
    }
  }
}

provider "aws" {
  # Configuration options
}

variable "prefix" {
  default = "aws-mol"
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.prefix}-public-subnet"
  }
}

# EIP for Internet Gateway
resource "aws_eip" "igw_eip" {
  vpc = true
  tags = {
    Name = "${var.prefix}_igw_eip"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_igw"
  }
}

# Provides Route Table for Public Subnet
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.prefix}_pub_rt"
  }
}

# Associates Public Subnet with the Public Route Table
resource "aws_route_table_association" "pub_sub1_rta" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.pub_rt.id
}

# Provides Security Group for Public HTTP Access
resource "aws_security_group" "pub_http_sg" {
  name        = "http_access_public"
  description = "Allows HTTP access from the public internet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "HTTP port 80 from public internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTP port 80 to public internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "public_http_access_sg"
  }
}

# AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  subnet_id = aws_subnet.public.id
  instance_type = "t3.micro"
  associate_public_ip_address = true
  availability_zone = "us-east-1a"
  vpc_security_group_ids      = [aws_security_group.pub_http_sg.id]
  
  ebs_block_device {
    delete_on_termination = "true"
    device_name = "/dev/sda1"
    volume_size = "8"
  }

  tags = {
    Name = "${var.prefix}-web"
  }
}

