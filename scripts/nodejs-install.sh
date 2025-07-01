#!/bin/bash

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | sudo -E bash -
apt-get install -y nodejs

# Install PM2 for process management
npm install -g pm2