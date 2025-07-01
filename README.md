# Generic Web Server Infrastructure

This Terraform configuration creates a modular AWS infrastructure for web applications with support for both Node.js and Python backends.

## What's Included

- **EC2 Instance**: Ubuntu 22.04 LTS with prepared setup scripts
- **Security Group**: Allows SSH (22), HTTP (80), HTTPS (443), and configurable app port
- **Elastic IP**: Static IP address for the instance
- **Key Pair**: SSH key management with auto-generation option
- **Ready-to-Run Scripts**: Pre-configured setup scripts in `~/setup-scripts/`
- **Multi-Language Support**: Node.js or Python runtime environments
- **Flexible Setup**: Choose which components to install

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
Uses `user_data.sh` - creates setup scripts for Node.js, PM2, and Nginx.

### Python Applications
Switch to Python setup by updating `main.tf`:
```hcl
user_data = base64encode(templatefile("${path.module}/user_data_python.sh", {
  python_version = var.python_version
  project_name = var.project_name
  app_port = var.app_port
  scripts = {
    system_update = file("${path.module}/scripts/system-update.sh")
    aws_cli_install = file("${path.module}/scripts/aws-cli-install.sh")
  }
}))
```

## Setup Scripts

After deployment, find ready-to-run scripts in `~/setup-scripts/`:

**Node.js Setup:**
- `system-update.sh` - System updates and essential packages
- `nodejs-install.sh` - Node.js and PM2 installation
- `nginx-setup.sh` - Nginx configuration for Node.js apps
- `app-setup.sh` - Application directory and deployment script
- `aws-cli-install.sh` - AWS CLI installation
- `setup-all.sh` - Run all scripts at once

**Python Setup:**
- `system-update.sh` - System updates and essential packages
- `python-install.sh` - Python and dependencies installation
- `nginx-setup.sh` - Nginx configuration for Python apps
- `app-setup.sh` - Application directory and deployment script
- `aws-cli-install.sh` - AWS CLI installation
- `setup-all.sh` - Run all scripts at once

## Server Setup

After infrastructure is ready, SSH to the server and run setup scripts:

```bash
# SSH to the server
ssh -i <key-file> ubuntu@<PUBLIC_IP>

# Check available setup scripts
cd ~/setup-scripts
cat README.md

# Run all setup scripts at once
./setup-all.sh

# Or run individual scripts as needed
sudo ./system-update.sh
sudo ./nodejs-install.sh     # or python-install.sh for Python
sudo ./nginx-setup.sh
sudo ./app-setup.sh
sudo ./aws-cli-install.sh
```

## Application Deployment

After server setup, deploy your application:

```bash
# Upload your code (example with rsync)
rsync -avz --exclude='node_modules/' --exclude='.git/' \
  -e 'ssh -i <key-file>' \
  ./ ubuntu@<PUBLIC_IP>:~/<project-name>/

# Use the generated deployment script
./deploy.sh

# Or implement your own deployment strategy
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
| `create_iam_role` | Auto-create IAM role | `false` |
| `iam_instance_profile` | Existing IAM instance profile | `""` |
| `iam_policies` | IAM policies for created role | `["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]` |

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

### With Custom IAM Role
```hcl
project_name = "my-app"
create_iam_role = true
iam_policies = [
  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
]
```

### With Existing IAM Profile
```hcl
project_name = "my-app"
create_iam_role = false
iam_instance_profile = "my-existing-profile"
```

## Cleanup

To destroy the infrastructure:

```bash
terraform destroy
```

## Benefits of Script Preparation Approach

- **Faster Instance Startup**: No long-running setup during boot
- **User Control**: Choose which components to install
- **Debugging Friendly**: Run scripts individually if something fails
- **Customizable**: Modify scripts before running if needed
- **Transparent**: See exactly what each script does
- **Flexible**: Skip components you don't need

## Security Notes

- Security group allows access from anywhere (0.0.0.0/0)
- Consider restricting SSH access to your IP for production
- Root volume is encrypted by default
- Use IAM roles for production deployments