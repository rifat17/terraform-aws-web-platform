#!/bin/bash

# Create application directory
mkdir -p /home/ubuntu/${project_name}
chown ubuntu:ubuntu /home/ubuntu/${project_name}

# Create a simple deployment script
cat > /home/ubuntu/deploy.sh << 'EOF'
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
EOF

chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh