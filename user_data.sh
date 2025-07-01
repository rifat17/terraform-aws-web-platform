#!/bin/bash

# Create scripts directory
mkdir -p /tmp/scripts

# Create individual script files
cat > /tmp/scripts/system-update.sh << 'EOF'
${scripts.system_update}
EOF

cat > /tmp/scripts/nodejs-install.sh << 'EOF'
${scripts.nodejs_install}
EOF

cat > /tmp/scripts/nginx-setup.sh << 'EOF'
${scripts.nginx_setup}
EOF

cat > /tmp/scripts/app-setup.sh << 'EOF'
${scripts.app_setup}
EOF

cat > /tmp/scripts/aws-cli-install.sh << 'EOF'
${scripts.aws_cli_install}
EOF

# Make scripts executable
chmod +x /tmp/scripts/*.sh

# System update and essential packages
/tmp/scripts/system-update.sh

# Node.js and PM2 installation
/tmp/scripts/nodejs-install.sh

# Nginx setup and configuration
# /tmp/scripts/nginx-setup.sh

# Application directory and deployment script
# /tmp/scripts/app-setup.sh

# AWS CLI installation
# /tmp/scripts/aws-cli-install.sh

echo "Server setup completed!" > /var/log/user-data.log