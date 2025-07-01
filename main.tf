terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# Data source for latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Security Group
resource "aws_security_group" "web_sg" {
  name_prefix = "${var.project_name}-web-"
  description = "Security group for ${var.project_name} web application"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Application Server"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-web-security-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Generate SSH key pair locally if create_key_pair is true
resource "tls_private_key" "ssh_key" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally
resource "local_file" "private_key" {
  count           = var.create_key_pair ? 1 : 0
  content         = tls_private_key.ssh_key[0].private_key_pem
  filename        = "${var.key_name}.pem"
  file_permission = "0400"
}

# Save public key locally
resource "local_file" "public_key" {
  count           = var.create_key_pair ? 1 : 0
  content         = tls_private_key.ssh_key[0].public_key_openssh
  filename        = "${var.key_name}.pub"
  file_permission = "0644"
}

# Create AWS key pair if needed
resource "aws_key_pair" "ssh_key" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = tls_private_key.ssh_key[0].public_key_openssh

  tags = {
    Name        = var.key_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.create_key_pair ? aws_key_pair.ssh_key[0].key_name : var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  root_block_device {
    volume_type = var.storage_type
    volume_size = var.storage_size
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    node_version = var.node_version
    project_name = var.project_name
    app_port     = var.app_port
    scripts = {
      system_update   = file("${path.module}/scripts/system-update.sh")
      nodejs_install  = file("${path.module}/scripts/nodejs-install.sh")
      nginx_setup     = file("${path.module}/scripts/nginx-setup.sh")
      app_setup       = file("${path.module}/scripts/app-setup.sh")
      aws_cli_install = file("${path.module}/scripts/aws-cli-install.sh")
    }
  }))

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Elastic IP
resource "aws_eip" "web_eip" {
  instance = aws_instance.web_server.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-web-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}
