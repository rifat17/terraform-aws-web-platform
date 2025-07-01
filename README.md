# Generic Web Server Infrastructure

This Terraform configuration creates a modular AWS infrastructure for web applications with support for both Node.js and Python backends.

## What's Included

- **EC2 Instance**: Ubuntu 22.04 LTS with auto-configuration
- **Security Group**: Allows SSH (22), HTTP (80), HTTPS (443), and app dev server (3000/8000)
- **Elastic IP**: Static IP address for the instance
- **Key Pair**: SSH key management with auto-generation option
- **Modular Setup Scripts**: Separate scripts for different components
- **Multi-Language Support**: Node.js or Python runtime environments

## Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed (>= 1.0)
3. SSH key pair (can be auto-generated)

## Quick Start

1. **Configure variables** (create `terraform.tfvars`):
   ```hcl
   project_name = "my-web-app"
   aws_region = "us-east-1"
   create_key_pair = true  # Auto-generate SSH key
   ```

2. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Get connection details**:
   ```bash
   terraform output
   ```

## Application Types

### Node.js Applications (Default)
Uses `user_data.sh` with Node.js, PM2, and Nginx configured for port 3000.

### Python Applications
Switch to Python setup by updating `main.tf`:
```hcl
user_data = base64encode(templatefile("${path.module}/user_data_python.sh", {
  python_version = var.python_version
  project_name = var.project_name
  scripts = {
    system_update        = file("${path.module}/scripts/system-update.sh")
    python_install       = file("${path.module}/scripts/python-install.sh")
    nginx_setup_python   = file("${path.module}/scripts/nginx-setup-python.sh")
    python_app_setup     = file("${path.module}/scripts/python-app-setup.sh")
    aws_cli_install      = file("${path.module}/scripts/aws-cli-install.sh")
  }
}))
```

## Modular Scripts

Scripts are organized by responsibility in the `scripts/` directory:
- `system-update.sh` - System updates and essential packages
- `nodejs-install.sh` / `python-install.sh` - Runtime installation
- `nginx-setup.sh` / `nginx-setup-python.sh` - Web server configuration
- `app-setup.sh` / `python-app-setup.sh` - Application setup
- `aws-cli-install.sh` - AWS CLI installation

Comment out any script execution in `user_data.sh` to skip components.

## Deployment

After infrastructure is ready:

```bash
# SSH to the server
ssh -i <key-file> ubuntu@<PUBLIC_IP>

# Deploy your application
./deploy.sh
```

## Configuration Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_name` | Project name for resources | `my-web-app` |
| `aws_region` | AWS region | `ap-south-1` |
| `aws_profile` | AWS profile | `hasib` |
| `environment` | Environment name | `development` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `storage_size` | Root volume size (GB) | `30` |
| `storage_type` | Root volume type | `gp3` |
| `create_key_pair` | Auto-generate SSH key | `false` |
| `key_name` | SSH key pair name | `web-key` |
| `private_key_path` | Path to private key | `./shared-key.pem` |
| `node_version` | Node.js version | `20` |
| `python_version` | Python version | `3.11` |
| `app_port` | Application port | `3000` |

## Examples

### Node.js + Next.js Project
```hcl
project_name = "my-nextjs-app"
node_version = "20"
app_port = 3000
create_key_pair = true
```

### Python + Django Project
```hcl
project_name = "my-django-app"
python_version = "3.11"
app_port = 8000
create_key_pair = true
```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

## Security Notes

- Security group allows access from anywhere (0.0.0.0/0)
- Consider restricting SSH access to your IP for production
- Root volume is encrypted by default
- Use IAM roles for production deployments