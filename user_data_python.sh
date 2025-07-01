#!/bin/bash

# Create scripts directory
mkdir -p /tmp/scripts

# Create individual script files
cat > /tmp/scripts/system-update.sh << 'EOF'
${scripts.system_update}
EOF

cat > /tmp/scripts/python-install.sh << 'EOF'
${scripts.python_install}
EOF

# Replace python_version placeholder
sed -i 's/\${python_version}/${python_version}/g' /tmp/scripts/python-install.sh

# Replace app_port placeholder in scripts
sed -i 's/\${app_port}/${app_port}/g' /tmp/scripts/nginx-setup-python.sh
sed -i 's/\${app_port}/${app_port}/g' /tmp/scripts/python-app-setup.sh

cat > /tmp/scripts/nginx-setup-python.sh << 'EOF'
${scripts.nginx_setup_python}
EOF

cat > /tmp/scripts/python-app-setup.sh << 'EOF'
${scripts.python_app_setup}
EOF

cat > /tmp/scripts/aws-cli-install.sh << 'EOF'
${scripts.aws_cli_install}
EOF

# Make scripts executable
chmod +x /tmp/scripts/*.sh

# System update and essential packages
/tmp/scripts/system-update.sh

# Python installation
/tmp/scripts/python-install.sh

# Nginx setup and configuration
# /tmp/scripts/nginx-setup-python.sh

# Application directory and deployment script
# /tmp/scripts/python-app-setup.sh

# AWS CLI installation
# /tmp/scripts/aws-cli-install.sh

echo "Python server setup completed!" > /var/log/user-data.log