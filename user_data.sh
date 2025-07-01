#!/bin/bash

# Create setup scripts directory in user home
mkdir -p /home/ubuntu/setup-scripts
chown ubuntu:ubuntu /home/ubuntu/setup-scripts

# Create individual script files
cat > /home/ubuntu/setup-scripts/system-update.sh << 'EOF'
${scripts.system_update}
EOF

# Create nodejs install script with direct substitution
cat > /home/ubuntu/setup-scripts/nodejs-install.sh << EOF
#!/bin/bash

# Install Node.js using NodeSource (simple and reliable)
echo "Installing Node.js version ${node_version}..."
curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | bash -
apt-get install -y nodejs

# Verify installation
echo "Node.js version: \$(node --version)"
echo "npm version: \$(npm --version)"

# Install PM2 for process management
echo "Installing PM2..."
npm install -g pm2

# Verify PM2 installation
echo "PM2 version: \$(pm2 --version)"
EOF

# Create nginx setup script with direct substitution
cat > /home/ubuntu/setup-scripts/nginx-setup.sh << EOF
#!/bin/bash

# Install Nginx
apt-get install -y nginx

# Configure Nginx for Next.js
cat > /etc/nginx/sites-available/${project_name}-web << 'NGINX_EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX_EOF

# Enable the site
ln -sf /etc/nginx/sites-available/${project_name}-web /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t && systemctl restart nginx
systemctl enable nginx
EOF

# Create app setup script with direct substitution
cat > /home/ubuntu/setup-scripts/app-setup.sh << EOF
#!/bin/bash

# Create application directory
mkdir -p /home/ubuntu/${project_name}
chown ubuntu:ubuntu /home/ubuntu/${project_name}

# Create a simple deployment script
cat > /home/ubuntu/deploy.sh << 'DEPLOY_EOF'
#!/bin/bash
cd /home/ubuntu/${project_name}

# Install dependencies
npm install

# Build the application
npm run build

# Stop existing PM2 process
pm2 stop ${project_name} || true

# Start the application with PM2
pm2 start npm --name "${project_name}" -- start

# Save PM2 configuration
pm2 save
pm2 startup
DEPLOY_EOF

chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh
EOF

cat > /home/ubuntu/setup-scripts/aws-cli-install.sh << 'EOF'
${scripts.aws_cli_install}
EOF

# Create a master setup script
cat > /home/ubuntu/setup-scripts/setup-all.sh << 'EOF'
#!/bin/bash

echo "Running all setup scripts..."

# System update and essential packages
sudo ./system-update.sh

# Node.js and PM2 installation
sudo ./nodejs-install.sh

# Nginx setup and configuration
sudo ./nginx-setup.sh

# Application directory and deployment script
sudo ./app-setup.sh

# AWS CLI installation
sudo ./aws-cli-install.sh

echo "Setup completed!"
EOF

# Create README for the scripts
cat > /home/ubuntu/setup-scripts/README.md << 'EOF'
# Setup Scripts

These scripts will configure your server for Node.js applications.

## Individual Scripts

- `system-update.sh` - Update system and install essential packages
- `nodejs-install.sh` - Install Node.js ${node_version} and PM2
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
sudo ./nodejs-install.sh
sudo ./nginx-setup.sh
sudo ./app-setup.sh
sudo ./aws-cli-install.sh
```

## Project Configuration

- Project name: ${project_name}
- Node.js version: ${node_version}
- Application port: ${app_port}
EOF

# Make all scripts executable and set proper ownership
chmod +x /home/ubuntu/setup-scripts/*.sh
chown -R ubuntu:ubuntu /home/ubuntu/setup-scripts

echo "Setup scripts prepared in /home/ubuntu/setup-scripts/" >> /var/log/user-data.log