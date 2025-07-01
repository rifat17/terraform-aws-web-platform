#!/bin/bash

# Create application directory
mkdir -p /home/ubuntu/app
chown ubuntu:ubuntu /home/ubuntu/app

# Create virtual environment
python3 -m venv /home/ubuntu/app/venv
chown -R ubuntu:ubuntu /home/ubuntu/app/venv

# Create deployment script
cat > /home/ubuntu/deploy.sh << 'EOF'
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
EOF

chmod +x /home/ubuntu/deploy.sh
chown ubuntu:ubuntu /home/ubuntu/deploy.sh

# Create systemd service for auto-start
cat > /etc/systemd/system/python-app.service << 'EOF'
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
EOF

systemctl enable python-app