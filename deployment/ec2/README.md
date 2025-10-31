# EC2 t3.small Deployment Guide

## 🚀 **Complete Deployment Guide for CallWaitingAI on EC2 t3.small**

This guide provides step-by-step instructions for deploying CallWaitingAI on AWS EC2 t3.small instance with Docker containerization.

## 📋 **Prerequisites**

- AWS Account with EC2 access
- EC2 t3.small instance (2 vCPU, 2GB RAM)
- Amazon Linux 2 AMI
- Security Group configured for ports 22, 80, 443
- Domain name (optional, for SSL)

## 🏗️ **Architecture Overview**

```
Internet → Nginx (Port 80/443) → Backend (Port 3000)
                                ↓
                         Rasa Server (Port 5005)
                                ↓
                         Rasa Actions (Port 5055)
```

## 🔧 **Step 1: Launch EC2 Instance**

1. **Launch t3.small instance:**
   ```bash
   # Instance specifications
   - Type: t3.small (2 vCPU, 2GB RAM)
   - AMI: Amazon Linux 2
   - Storage: 20GB GP3 SSD (minimum)
   - Security Group: Allow ports 22, 80, 443
   ```

2. **Connect to instance:**
   ```bash
   ssh -i your-key.pem ec2-user@your-instance-ip
   ```

## 🛠️ **Step 2: Initial Server Setup**

1. **Run the setup script:**
   ```bash
   # Download and run setup script
   curl -fsSL https://raw.githubusercontent.com/Odiabackend099/rasa-logic/main/deployment/ec2/setup-ec2.sh | bash
   
   # Or manually:
   wget https://raw.githubusercontent.com/Odiabackend099/rasa-logic/main/deployment/ec2/setup-ec2.sh
   chmod +x setup-ec2.sh
   ./setup-ec2.sh
   ```

2. **Log out and back in** (for Docker group changes):
   ```bash
   exit
   ssh -i your-key.pem ec2-user@your-instance-ip
   ```

## 📦 **Step 3: Deploy Application**

1. **Run deployment script:**
   ```bash
   # Download and run deployment script
   curl -fsSL https://raw.githubusercontent.com/Odiabackend099/rasa-logic/main/deployment/ec2/deploy.sh | bash
   ```

2. **Configure environment variables:**
   ```bash
   cd /home/ec2-user/callwaitingai
   cp deployment/ec2/.env.template backend/.env.production
   nano backend/.env.production
   ```

   **Required variables:**
   ```env
   SUPABASE_URL=your-supabase-url
   SUPABASE_KEY=your-supabase-key
   TWILIO_ACCOUNT_SID=your-twilio-sid
   TWILIO_AUTH_TOKEN=your-twilio-token
   TWILIO_PHONE_NUMBER=your-twilio-number
   TWILIO_WEBHOOK_BASE_URL=https://your-domain.com
   ```

3. **Restart services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## 🔒 **Step 4: Set Up SSL (Production)**

1. **Install Certbot:**
   ```bash
   sudo yum install -y certbot python3-certbot-nginx
   ```

2. **Get SSL certificate:**
   ```bash
   sudo certbot --nginx -d your-domain.com
   ```

3. **Update Nginx configuration:**
   ```bash
   # Certbot will automatically update nginx.conf
   sudo systemctl reload nginx
   ```

## 🔄 **Step 5: Set Up Auto-Start Service**

1. **Install systemd service:**
   ```bash
   sudo cp /home/ec2-user/callwaitingai/deployment/ec2/callwaitingai.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable callwaitingai
   sudo systemctl start callwaitingai
   ```

2. **Check service status:**
   ```bash
   sudo systemctl status callwaitingai
   ```

## 📊 **Step 6: Monitoring and Maintenance**

### **Health Checks**
```bash
# Check application health
./health-check.sh

# Monitor resources
./monitor.sh

# View logs
docker-compose logs -f [service-name]
```

### **Resource Monitoring**
```bash
# System resources
htop

# Docker stats
docker stats

# Disk usage
df -h
```

### **Log Management**
```bash
# View application logs
docker-compose logs -f backend
docker-compose logs -f rasa-server
docker-compose logs -f rasa-actions

# System logs
sudo journalctl -u callwaitingai -f
```

## 🔄 **Updates and Maintenance**

### **Update Application**
```bash
./update-app.sh
```

### **Manual Update Process**
```bash
cd /home/ec2-user/callwaitingai
git pull origin main
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### **Backup Important Data**
```bash
# Backup environment files
cp backend/.env.production ~/backup-env-$(date +%Y%m%d).txt

# Backup SSL certificates
sudo cp -r /etc/letsencrypt ~/ssl-backup-$(date +%Y%m%d)
```

## 🧪 **Testing Deployment**

### **Health Check Endpoints**
```bash
# Application health
curl https://your-domain.com/health

# Backend API
curl https://your-domain.com/api/health

# Rasa server
curl https://your-domain.com/rasa/health

# Test conversation
curl -X POST https://your-domain.com/rasa/webhooks/rest/webhook \
  -H "Content-Type: application/json" \
  -d '{"sender":"test","message":"hello"}'
```

### **Load Testing**
```bash
# Install Apache Bench
sudo yum install -y httpd-tools

# Basic load test
ab -n 100 -c 10 https://your-domain.com/health
```

## 🚨 **Troubleshooting**

### **Common Issues**

1. **Out of Memory:**
   ```bash
   # Check memory usage
   free -h
   docker stats
   
   # Restart services
   docker-compose restart
   ```

2. **Service Not Starting:**
   ```bash
   # Check logs
   docker-compose logs [service-name]
   
   # Check Docker daemon
   sudo systemctl status docker
   ```

3. **SSL Issues:**
   ```bash
   # Check certificate
   sudo certbot certificates
   
   # Renew certificate
   sudo certbot renew --dry-run
   ```

### **Performance Optimization**

1. **For t3.small (2GB RAM):**
   ```bash
   # Monitor memory usage
   watch -n 1 'free -h && echo "---" && docker stats --no-stream'
   
   # Optimize Docker
   sudo systemctl edit docker
   # Add: Environment="DOCKER_OPTS=--default-ulimit memlock=-1:-1"
   ```

2. **Database Connection Pooling:**
   - Configure Supabase connection limits
   - Monitor active connections

## 📈 **Scaling Considerations**

### **Vertical Scaling (Upgrade Instance)**
- t3.medium (2 vCPU, 4GB RAM) - Better for higher traffic
- t3.large (2 vCPU, 8GB RAM) - Production workloads

### **Horizontal Scaling**
- Load balancer with multiple instances
- Separate database server
- CDN for static assets

## 🔐 **Security Best Practices**

1. **Firewall Configuration:**
   ```bash
   # Check current rules
   sudo iptables -L
   
   # Only allow necessary ports
   sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
   ```

2. **Regular Updates:**
   ```bash
   # System updates
   sudo yum update -y
   
   # Application updates
   ./update-app.sh
   ```

3. **Monitoring:**
   - Set up CloudWatch alarms
   - Configure log aggregation
   - Monitor SSL certificate expiration

## 📞 **Support**

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Run health check: `./health-check.sh`
3. Monitor resources: `./monitor.sh`
4. Review this documentation

## 🎯 **Production Checklist**

- [ ] EC2 instance launched and configured
- [ ] Docker and Docker Compose installed
- [ ] Application deployed and running
- [ ] Environment variables configured
- [ ] SSL certificate installed
- [ ] Systemd service enabled
- [ ] Health checks passing
- [ ] Monitoring set up
- [ ] Backup strategy implemented
- [ ] Domain DNS configured
- [ ] Firewall rules applied
- [ ] Performance testing completed

---

**Deployment completed successfully! 🎉**

Your CallWaitingAI application is now running on EC2 t3.small with:
- Ultra-lightweight Rasa configuration
- Docker containerization
- Nginx reverse proxy
- SSL termination
- Auto-restart capabilities
- Health monitoring
- Log management