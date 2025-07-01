#!/bin/bash

# Create setup scripts directory in user home
mkdir -p /home/ubuntu/setup-scripts
chown ubuntu:ubuntu /home/ubuntu/setup-scripts

# Create individual script files
cat > /home/ubuntu/setup-scripts/system-update.sh << 'EOF'
${scripts.system_update}
EOF

# Create python install script with direct substitution
cat > /home/ubuntu/setup-scripts/python-install.sh << EOF
#!/bin/bash

# Add deadsnakes PPA for specific Python versions
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update -y

# Install specific Python version
apt-get install -y python${python_version} python${python_version}-pip python${python_version}-venv python${python_version}-dev

# Create symlinks for python3 and pip3 to point to specific version
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${python_version} 1
update-alternatives --install /usr/bin/pip3 pip3 /usr/bin/pip${python_version} 1

# Install process managers
pip3 install gunicorn supervisor

# Install common Python packages
pip3 install virtualenv
EOF

# Create nginx setup script with direct substitution
cat > /home/ubuntu/setup-scripts/nginx-setup.sh << EOF
#!/bin/bash

# Install Nginx
apt-get install -y nginx

# Configure Nginx for Python apps (Django/Flask/FastAPI)
cat > /etc/nginx/sites-available/${project_name}-app << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /static/ {
        alias /home/ubuntu/app/static/;
    }

    location /media/ {
        alias /home/ubuntu/app/media/;
    }
}
NGINX_EOF

# Enable the site
ln -sf /etc/nginx/sites-available/${project_name}-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t && systemctl restart nginx
systemctl enable nginx
EOF

# Create python app setup script with direct substitution
cat > /home/ubuntu/setup-scripts/app-setup.sh << EOF
#!/bin/bash

# Create application directory
mkdir -p /home/ubuntu/app
chown ubuntu:ubuntu /home/ubuntu/app

# Create virtual environment
python3 -m venv /home/ubuntu/app/venv
chown -R ubuntu:ubuntu /home/ubuntu/app/venv

# Create deployment script
cat > /home/ubuntu/deploy.sh << 'DEPLOY_EOF'
#!/bin/bash
cd /home/ubuntu/app

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Django specific commands (comment out if not using Django)
python manage.py migrate
python manage.py collectstatic --noinput

# Stop existing gunicorn process
pkill -f gunicorn || true

# Start application with gunicorn
gunicorn --bind 0.0.0.0:${app_port} --workers 3 --daemon wsgi:application

# For FastAPI, use: gunicorn -w 3 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:${app_port} --daemon
DEPLOY_EOF

chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh

# Create systemd service for auto-start
cat > /etc/systemd/system/python-app.service << 'SERVICE_EOF'
[Unit]
Description=Python Web Application
After=network.target

[Service]
User=ubuntu
Group=ubuntu
WorkingDirectory=/home/ubuntu/app
Environment=PATH=/home/ubuntu/app/venv/bin
ExecStart=/home/ubuntu/app/venv/bin/gunicorn --bind 0.0.0.0:${app_port} --workers 3 wsgi:application
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE_EOF

systemctl enable python-app
EOF

cat > /home/ubuntu/setup-scripts/aws-cli-install.sh << 'EOF'
${scripts.aws_cli_install}
EOF

# Create a master setup script
cat > /home/ubuntu/setup-scripts/setup-all.sh << 'EOF'
#!/bin/bash

echo "Running all Python setup scripts..."

# System update and essential packages
sudo ./system-update.sh

# Python installation
sudo ./python-install.sh

# Nginx setup and configuration
sudo ./nginx-setup.sh

# Application directory and deployment script
sudo ./app-setup.sh

# AWS CLI installation
sudo ./aws-cli-install.sh

echo "Python setup completed!"
EOF

# Create README for the scripts
cat > /home/ubuntu/setup-scripts/README.md << 'EOF'
# Python Setup Scripts

These scripts will configure your server for Python applications.

## Individual Scripts

- `system-update.sh` - Update system and install essential packages
- `python-install.sh` - Install Python ${python_version} and dependencies
- `nginx-setup.sh` - Install and configure Nginx for ${project_name}
- `app-setup.sh` - Create application directory and deployment script
- `aws-cli-install.sh` - Install AWS CLI

## Usage

### Run all scripts:
```bash
cd ~/setup-scripts
./setup-all.sh
```

### Run individual scripts:
```bash
cd ~/setup-scripts
sudo ./system-update.sh
sudo ./python-install.sh
sudo ./nginx-setup.sh
sudo ./app-setup.sh
sudo ./aws-cli-install.sh
```

## Project Configuration

- Project name: ${project_name}
- Python version: ${python_version}
- Application port: ${app_port}
EOF

# Make all scripts executable and set proper ownership
chmod +x /home/ubuntu/setup-scripts/*.sh
chown -R ubuntu:ubuntu /home/ubuntu/setup-scripts

echo "Python setup scripts prepared in /home/ubuntu/setup-scripts/" >> /var/log/user-data.log