#!/bin/bash

# Update system
apt-get update -y
apt-get upgrade -y

# Install essential packages
apt-get install -y curl wget git unzip software-properties-common