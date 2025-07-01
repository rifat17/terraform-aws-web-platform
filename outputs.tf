output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.web_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.web_server.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}

output "private_key_file" {
  description = "Path to private key file"
  value       = var.create_key_pair ? "${var.key_name}.pem" : var.private_key_path
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.create_key_pair ? "${var.key_name}.pem" : var.private_key_path} ubuntu@${aws_eip.web_eip.public_ip}"
}

output "rsync_command" {
  description = "Rsync command to deploy files"
  value       = "rsync -avz --progress --exclude='.next/' --exclude='node_modules/' --exclude='.git/' -e 'ssh -i ${var.create_key_pair ? "${var.key_name}.pem" : var.private_key_path}' ./ ubuntu@${aws_eip.web_eip.public_ip}:/home/ubuntu/${var.project_name}"
}