# 🚀 CallWaitingAI - Unified Conversational AI System

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/docs/blueprint-spec)

**Self-hosted Rasa Open Source conversational AI system with MiniMax TTS integration, multi-channel support, and production-ready deployment configurations.**

## 🎯 **Quick Start - One Command Deployment**

```bash
# Clone the unified repository
git clone https://github.com/Odiabackend099/rasa-logic.git
cd rasa-logic

# Deploy locally (development)
./deploy.sh local

# Deploy with Docker (production-like)
./deploy.sh docker

# Deploy to EC2 t3.small
./deploy.sh ec2

# Deploy to Render
./deploy.sh render
```

## 📁 **Unified Repository Structure**

```
callwaitingai-unified/
├── 📦 package.json              # Unified npm scripts for all operations
├── 🐳 docker-compose.yml        # Complete containerization
├── 🚀 deploy.sh                 # One-command deployment script
├── 🔧 .env.example              # Unified environment configuration
│
├── backend/                     # Node.js API Server
│   ├── 🐳 Dockerfile           # Production-ready container
│   ├── 📦 package.json         # Backend dependencies
│   ├── 🚀 server.js            # Main server file
│   ├── 🛣️  routes/             # API endpoints (chat, voice, webhooks)
│   ├── 🔧 services/            # STT/TTS integrations
│   └── 🛡️  middleware/         # Validation, security
│
├── rasa-agent/                  # Rasa Conversational AI
│   ├── 🐳 Dockerfile.server    # Ultra-lightweight Rasa server
│   ├── 🐳 Dockerfile.actions   # Actions server with MiniMax TTS
│   ├── ⚙️  config-production.yml # Optimized for 512MB-2GB RAM
│   ├── 🎯 data/               # Training data (NLU, stories, rules)
│   ├── 🎭 domain.yml          # Conversation domain
│   ├── ⚡ actions/            # Custom actions (TTS, database)
│   └── 📦 requirements-production.txt # Ultra-light dependencies
│
├── deployment/                  # Production Deployment
│   └── ec2/                    # AWS EC2 deployment
│       ├── 🚀 setup-ec2.sh    # Complete EC2 instance setup
│       ├── 📦 deploy.sh       # Application deployment
│       ├── 🔧 .env.template   # Production environment
│       ├── 🔄 callwaitingai.service # Systemd service
│       └── 📖 README.md       # Detailed deployment guide
│
├── nginx/                      # Reverse Proxy & SSL
│   ├── ⚙️  nginx.conf         # Production configuration
│   └── 🔒 ssl/               # SSL certificates
│
└── database/                   # Supabase Database
    ├── 📊 schema.sql          # Database schema
    └── 🔧 SUPABASE_SETUP.sql  # Setup instructions
```

## ✨ **Features**

### 🤖 **Conversational AI**
- **Ultra-lightweight Rasa** - Optimized for 512MB-2GB RAM
- **Multi-language support** - English and Nigerian Pidgin
- **Intent recognition** - Business inquiries, lead capture, love meditation
- **Context management** - Session-based conversations
- **Fallback handling** - Graceful error recovery

### 🎵 **Voice Integration**
- **MiniMax TTS** - High-quality text-to-speech with African male voice
- **Multiple voice options** - Soft, natural, professional tones
- **Real-time synthesis** - Fast audio generation and streaming
- **Voice customization** - Speed, volume, pitch control

### 📱 **Multi-Channel Support**
- **Web API** - RESTful endpoints for web applications
- **Twilio Voice** - Phone call integration with STT/TTS
- **WhatsApp Business** - WhatsApp messaging integration
- **Telegram Bot** - Telegram channel support
- **Webhook support** - Easy integration with external systems

### 🏗️ **Production-Ready Architecture**
- **Docker containerization** - Complete orchestration with health checks
- **Nginx reverse proxy** - SSL termination, rate limiting, security
- **Auto-scaling ready** - Horizontal and vertical scaling support
- **Monitoring & logging** - Comprehensive observability
- **CI/CD ready** - Automated deployment pipelines

## 🚀 **Deployment Options**

### 1. **Local Development**
```bash
# Quick start
npm run install:all
npm run train
npm run dev

# Or use unified script
./deploy.sh local
```

**Services:**
- Backend: http://localhost:3000
- Rasa: http://localhost:5005
- Actions: http://localhost:5055

### 2. **Docker Production**
```bash
# Build and deploy
./deploy.sh docker --clean

# Monitor
docker-compose logs -f
npm run monitor
```

**Access:** http://localhost (via Nginx)

### 3. **AWS EC2 t3.small**
```bash
# One-command EC2 deployment
./deploy.sh ec2

# Manual setup
curl -fsSL https://raw.githubusercontent.com/Odiabackend099/rasa-logic/main/deployment/ec2/setup-ec2.sh | bash
curl -fsSL https://raw.githubusercontent.com/Odiabackend099/rasa-logic/main/deployment/ec2/deploy.sh | bash
```

**Optimized for:**
- 2GB RAM (ultra-lightweight Rasa)
- 2 vCPU (single worker processes)
- SSL/TLS with Let's Encrypt
- Systemd auto-restart

### 4. **Render.com**
```bash
# Deploy to Render
./deploy.sh render

# Or manual push
git push origin main
```

**Features:**
- Auto-deployment on git push
- Built-in SSL certificates
- Environment variable management
- Automatic scaling

## ⚙️ **Configuration**

### **Environment Setup**
```bash
# Copy and configure environment
cp .env.example .env
# Edit .env with your credentials

# Key configurations:
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-key
MINIMAX_API_KEY=your-minimax-api-key
MINIMAX_GROUP_ID=your-group-id
TWILIO_ACCOUNT_SID=your-twilio-sid
```

### **Resource Optimization**
```bash
# For t3.small (2GB RAM)
OMP_NUM_THREADS=1
OPENBLAS_NUM_THREADS=1
RASA_MAX_TRAINING_PROCESSES=1

# For larger instances
OMP_NUM_THREADS=2
OPENBLAS_NUM_THREADS=2
RASA_MAX_TRAINING_PROCESSES=2
```

## 🧪 **Testing & Monitoring**

### **Health Checks**
```bash
# Check all services
npm run health

# Individual service checks
curl http://localhost:3000/health
curl http://localhost:5005/health
curl http://localhost:5055/health
```

### **Testing**
```bash
# Run all tests
npm run test

# Test conversation
npm run test:conversation

# Test specific components
npm run test:backend
npm run test:rasa
```

### **Monitoring**
```bash
# Resource monitoring
npm run monitor

# View logs
npm run docker:logs

# Health monitoring
./health-check.sh
```

## 📊 **API Endpoints**

### **Chat & Voice**
- `POST /api/chat` - Process chat message
- `POST /api/voice` - Process voice message
- `GET /api/session/:id` - Get conversation history

### **Webhooks**
- `POST /api/twilio/incoming` - Twilio voice calls
- `POST /api/whatsapp/webhook` - WhatsApp messages
- `POST /api/telegram/webhook` - Telegram messages

### **Analytics**
- `GET /api/analytics/dashboard` - Dashboard summary
- `GET /api/analytics/conversations` - Conversation analytics
- `GET /api/analytics/leads` - Lead statistics

## 🔧 **Development Commands**

```bash
# Installation
npm run install:all          # Install all dependencies
npm run install:backend      # Backend only
npm run install:rasa         # Rasa only

# Development
npm run dev                  # Start development servers
npm run dev:backend          # Backend development
npm run dev:rasa            # Rasa development
npm run dev:actions         # Actions development

# Training
npm run train               # Train production model
npm run train:minimal       # Train minimal model

# Docker
npm run docker:build        # Build containers
npm run docker:up           # Start containers
npm run docker:down         # Stop containers
npm run docker:restart      # Restart containers

# Deployment
npm run deploy:local        # Local deployment
npm run deploy:ec2          # EC2 deployment
npm run deploy:render       # Render deployment

# Maintenance
npm run clean               # Clean all artifacts
npm run update              # Update and rebuild
npm run health              # Health check
npm run monitor             # Resource monitoring
```

## 🔒 **Security Features**

- **Rate limiting** - API endpoint protection
- **CORS configuration** - Cross-origin request security
- **Input validation** - Request sanitization
- **SSL/TLS encryption** - End-to-end encryption
- **Security headers** - HSTS, XSS protection
- **Non-root containers** - Docker security best practices
- **Environment isolation** - Secure configuration management

## 📈 **Performance Optimizations**

### **Memory Efficiency**
- Ultra-lightweight Rasa configuration (embedding_dim=20)
- Minimal dependencies (no TensorFlow/JAX for 512MB deployments)
- Aggressive caching and cleanup
- Single worker processes for small instances

### **Network Optimization**
- Nginx reverse proxy with compression
- Connection pooling and keep-alive
- CDN-ready static asset serving
- Efficient API response caching

### **Database Optimization**
- Supabase connection pooling
- Optimized queries and indexing
- Session cleanup and management
- Analytics data aggregation

## 🆘 **Troubleshooting**

### **Common Issues**

1. **Out of Memory (OOM)**
   ```bash
   # Check memory usage
   npm run monitor
   
   # Use minimal configuration
   npm run train:minimal
   ```

2. **Service Not Starting**
   ```bash
   # Check logs
   npm run docker:logs
   
   # Restart services
   npm run docker:restart
   ```

3. **Health Check Failures**
   ```bash
   # Run health check
   npm run health
   
   # Check individual services
   curl http://localhost:3000/health
   ```

### **Performance Issues**
```bash
# Monitor resources
npm run monitor

# Clean and rebuild
npm run clean
npm run docker:build --no-cache
```

## 🤝 **Contributing**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 **License**

Apache 2.0 (same as Rasa Open Source)

## 🆘 **Support**

- **Documentation**: Check individual service README files
- **Issues**: GitHub Issues
- **Deployment Guide**: `deployment/ec2/README.md`
- **API Documentation**: Available at `/api/docs` when running

---

## 🎉 **Ready to Deploy!**

Your unified CallWaitingAI system is ready for production deployment with:

✅ **One-command deployment** across all environments  
✅ **Ultra-lightweight configuration** for cost-effective hosting  
✅ **Production-grade security** and monitoring  
✅ **Multi-channel integration** (Voice, WhatsApp, Telegram, Web)  
✅ **MiniMax TTS integration** with African male voice  
✅ **Auto-scaling and high availability** support  

**Start with:** `./deploy.sh local` for development or `./deploy.sh ec2` for production!

