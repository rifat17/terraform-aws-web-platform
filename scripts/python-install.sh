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