# Chapter 2. The 10-minute EC2 Web Server


## Instructions
- Open a Terminal
- `cd chapters/ch2/`
- `terraform init`
- `terraform apply --auto-approve`
- An SSH private key will be created in the current directory
- Look at the outputs and copy/paste the string to SSH to the EC2 instance.
- Also, go to the link in the outputs.

# Resources in this lab
- VPC
- Subnet
- Internet Gateway
- Route Table
- Security Groups
- EC2 Instance
- RSA 4096 Keys

## Goals
- Launch an EC2 Ubuntu Linux server instance
- Use SSH to connect with your instance
- Use the Ubuntu package manager to install the software packages it will need to run as a web server
- Create a simple Welcome page for your site