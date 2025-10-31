#!/bin/bash
# Complete EC2 t3.small setup script for CallWaitingAI
set -euo pipefail

echo "🚀 Setting up EC2 t3.small for CallWaitingAI deployment..."

# Update system packages
echo "📦 Updating system packages..."
sudo yum update -y

# Install essential packages
echo "🔧 Installing essential packages..."
sudo yum install -y \
    git \
    curl \
    wget \
    htop \
    nano \
    unzip \
    openssl \
    ca-certificates

# Install Docker
echo "🐳 Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
echo "🔧 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Configure Docker for t3.small (2GB RAM)
echo "⚙️  Configuring Docker for t3.small..."
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
  },
  "max-concurrent-downloads": 3,
  "max-concurrent-uploads": 3
}
EOF

# Restart Docker with new configuration
sudo systemctl restart docker

# Configure system limits for better performance
echo "⚡ Configuring system limits..."
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
# Limits for CallWaitingAI
ec2-user soft nofile 65536
ec2-user hard nofile 65536
ec2-user soft nproc 4096
ec2-user hard nproc 4096
EOF

# Configure sysctl for better network performance
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# Network optimizations for CallWaitingAI
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
EOF

sudo sysctl -p

# Set up log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/callwaitingai > /dev/null <<EOF
/home/ec2-user/callwaitingai/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ec2-user ec2-user
    postrotate
        docker-compose -f /home/ec2-user/callwaitingai/docker-compose.yml restart > /dev/null 2>&1 || true
    endscript
}
EOF

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /home/ec2-user/callwaitingai/logs
sudo chown -R ec2-user:ec2-user /home/ec2-user/callwaitingai

# Set up firewall rules
echo "🔥 Configuring firewall..."
sudo yum install -y iptables-services
sudo systemctl enable iptables

# Basic firewall rules
sudo iptables -F
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# Allow loopback
sudo iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (port 22)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP (port 80)
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Allow HTTPS (port 443)
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Save firewall rules
sudo service iptables save

# Install monitoring tools
echo "📊 Installing monitoring tools..."
sudo yum install -y htop iotop nethogs

# Create monitoring script
cat > /home/ec2-user/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script for CallWaitingAI

echo "=== System Resources ==="
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2 $3 $4 $5 $6 $7 $8}'

echo -e "\nMemory Usage:"
free -h

echo -e "\nDisk Usage:"
df -h /

echo -e "\n=== Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "\n=== Container Resources ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo -e "\n=== Recent Logs ==="
docker-compose -f /home/ec2-user/callwaitingai/docker-compose.yml logs --tail=10
EOF

chmod +x /home/ec2-user/monitor.sh

# Create update script
cat > /home/ec2-user/update-app.sh << 'EOF'
#!/bin/bash
# Update script for CallWaitingAI

set -euo pipefail

APP_DIR="/home/ec2-user/callwaitingai"

echo "🔄 Updating CallWaitingAI..."

cd $APP_DIR

# Pull latest changes
git pull origin main

# Rebuild and restart services
docker-compose down
docker-compose build --no-cache
docker-compose up -d

echo "✅ Update completed!"

# Show status
docker-compose ps
EOF

chmod +x /home/ec2-user/update-app.sh

# Set up automatic updates (optional)
echo "🔄 Setting up automatic security updates..."
sudo yum install -y yum-cron
sudo systemctl enable yum-cron
sudo systemctl start yum-cron

# Configure yum-cron for security updates only
sudo sed -i 's/update_cmd = default/update_cmd = security/' /etc/yum/yum-cron.conf
sudo sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf

# Create health check script
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
# Health check script for CallWaitingAI

HEALTH_URL="http://localhost/health"
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f -s $HEALTH_URL > /dev/null; then
        echo "✅ Application is healthy"
        exit 0
    else
        echo "❌ Health check failed (attempt $((RETRY_COUNT + 1))/$MAX_RETRIES)"
        RETRY_COUNT=$((RETRY_COUNT + 1))
        sleep 5
    fi
done

echo "🚨 Application is unhealthy after $MAX_RETRIES attempts"
echo "📊 Container status:"
docker-compose -f /home/ec2-user/callwaitingai/docker-compose.yml ps

echo "📝 Recent logs:"
docker-compose -f /home/ec2-user/callwaitingai/docker-compose.yml logs --tail=20

exit 1
EOF

chmod +x /home/ec2-user/health-check.sh

# Display system information
echo ""
echo "🎉 EC2 t3.small setup completed!"
echo ""
echo "📋 System Information:"
echo "   - Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)"
echo "   - Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   - Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "   - Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
echo ""
echo "🔧 Installed Software:"
echo "   - Docker: $(docker --version)"
echo "   - Docker Compose: $(docker-compose --version)"
echo "   - Git: $(git --version)"
echo ""
echo "📁 Created Files:"
echo "   - /home/ec2-user/monitor.sh - System monitoring"
echo "   - /home/ec2-user/update-app.sh - Application updates"
echo "   - /home/ec2-user/health-check.sh - Health checking"
echo ""
echo "🚀 Next Steps:"
echo "   1. Log out and log back in for Docker group changes"
echo "   2. Run the deployment script: ./deployment/ec2/deploy.sh"
echo "   3. Set up systemd service: sudo cp deployment/ec2/callwaitingai.service /etc/systemd/system/"
echo "   4. Enable service: sudo systemctl enable callwaitingai"
echo ""
echo "⚠️  Remember to:"
echo "   - Configure your environment variables"
echo "   - Set up SSL certificates for production"
echo "   - Configure your domain DNS"
echo "   - Set up monitoring and alerting"