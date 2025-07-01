#!/bin/bash

# Install Nginx
apt-get install -y nginx

# Configure Nginx for Python apps (Django/Flask/FastAPI)
cat > /etc/nginx/sites-available/python-app << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:${app_port};
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /static/ {
        alias /home/ubuntu/app/static/;
    }

    location /media/ {
        alias /home/ubuntu/app/media/;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/python-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t && systemctl restart nginx
systemctl enable nginx