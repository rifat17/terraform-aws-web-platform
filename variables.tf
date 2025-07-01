variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "hasib"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "storage_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "storage_type" {
  description = "Root volume type"
  type        = string
  default     = "gp3"
}

variable "create_key_pair" {
  description = "Whether to create a new key pair or use existing one"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "Name of the AWS key pair (existing or to be created)"
  type        = string
  default     = "web-key"
}

variable "private_key_path" {
  description = "Path to existing private key file (only used if create_key_pair is false)"
  type        = string
  default     = "./shared-key.pem"
}

variable "node_version" {
  description = "Node.js version to install"
  type        = string
  default     = "20"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "my-web-app"
}

variable "python_version" {
  description = "Python version to install"
  type        = string
  default     = "3.11"
}

variable "app_port" {
  description = "Application port (3000 for Node.js, 8000 for Python)"
  type        = number
  default     = 3000
}
