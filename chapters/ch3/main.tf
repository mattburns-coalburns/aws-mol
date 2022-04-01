###############################
#        Provider Block       #
###############################

# Provider Block
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.8.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "local" {}

provider "tls" {}

###############################
#          Variables          #
###############################

variable "prefix" {
  default = "aws-mol"
}

variable "region" {
  default = "us-east-1"
}

variable "az" {
  default = "us-east-1a"
}

###############################
#        Local SSH Key        #
###############################

# Creates RSA 4096-encrypted key pair
resource "tls_private_key" "web" {
  algorithm   = "RSA"
  ecdsa_curve = "4096"
}

# Saves the private .pem file locally
resource "local_file" "web" {
  filename        = "web_server.pem"
  file_permission = 0400
  content         = tls_private_key.web.private_key_pem
}

# Provides Public key to the Web Server EC2 instance
resource "aws_key_pair" "web" {
  key_name   = "web_server"
  public_key = tls_private_key.web.public_key_openssh
}

###############################
#             VPC             #
###############################

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
  availability_zone = var.az

  tags = {
    Name = "${var.prefix}-public-subnet"
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

# Provides Security Group for Public SSH Access
resource "aws_security_group" "pub_ssh_sg" {
  name        = "ssh_access_public"
  description = "Allows SSH access from the public internet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "SSH port 22 from public internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description      = "SSH port 22 to public internet"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "public_ssh_access_sg"
  }
}

###############################
#             EC2             #
###############################

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
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = aws_subnet.public.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name = aws_key_pair.web.key_name
  vpc_security_group_ids = [
    aws_security_group.pub_http_sg.id,
    aws_security_group.pub_ssh_sg.id
  ]

  ebs_block_device {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = "8"
  }

  user_data = <<-EOF
    #!/bin/bash
    apt update -y
    apt install apache2 \
      ghostscript \
      libapache2-mod-php \
      mysql-server \
      php \
      php-bcmath \
      php-curl \
      php-imagick \
      php-intl \
      php-json \
      php-mbstring \
      php-mysql \
      php-xml \
      php-zip -y
    systemctl enable apache2
    systemctl start apache2
    mkdir -p /srv/www
    chown www-data: /srv/www
    curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www 
    mysql -u root -e "create database wordpress";
    mysql -u root -e "CREATE USER 'wordpress'@'localhost' IDENTIFIED BY 'ThisPhr@seIsNotEncrypted'";
    mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* to 'wordpress'@'localhost'";
    mysql -u root -e "FLUSH PRIVILEGES";

    EOF

  tags = {
    Name = "${var.prefix}-web"
  }
}

###############################
#           Outputs           #
###############################
output "web_ssh" {
  value = "Type this in on a terminal to SSH connection to web server: ssh -i ${local_file.web.filename} ubuntu@${aws_instance.web.public_ip}"
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}/"
}