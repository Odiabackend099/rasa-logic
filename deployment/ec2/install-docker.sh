#!/bin/bash
# Docker installation script for EC2 t3.small (Amazon Linux 2)
set -euo pipefail

echo "🚀 Installing Docker on EC2 t3.small..."

# Update system
sudo yum update -y

# Install Docker
sudo yum install -y docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create symlink for docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Verify installations
echo "✅ Docker version:"
docker --version

echo "✅ Docker Compose version:"
docker-compose --version

# Configure Docker daemon for t3.small (2GB RAM)
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  }
}
EOF

# Restart Docker with new configuration
sudo systemctl restart docker

echo "🎉 Docker installation completed!"
echo "⚠️  Please log out and log back in for group changes to take effect"