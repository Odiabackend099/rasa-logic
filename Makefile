# CallWaitingAI Unified Makefile
# Provides convenient shortcuts for all deployment and development tasks

.PHONY: help install dev build deploy clean test health monitor

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

## Help - Show available commands
help:
	@echo "$(GREEN)🚀 CallWaitingAI - Unified Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)📦 Installation:$(NC)"
	@echo "  make install          Install all dependencies"
	@echo "  make install-backend  Install backend dependencies only"
	@echo "  make install-rasa     Install Rasa dependencies only"
	@echo ""
	@echo "$(YELLOW)🔧 Development:$(NC)"
	@echo "  make dev              Start development environment"
	@echo "  make dev-backend      Start backend development server"
	@echo "  make dev-rasa         Start Rasa development server"
	@echo "  make dev-actions      Start Rasa actions server"
	@echo ""
	@echo "$(YELLOW)🎯 Training:$(NC)"
	@echo "  make train            Train production Rasa model"
	@echo "  make train-minimal    Train minimal Rasa model"
	@echo ""
	@echo "$(YELLOW)🐳 Docker:$(NC)"
	@echo "  make docker-build     Build Docker containers"
	@echo "  make docker-up        Start Docker containers"
	@echo "  make docker-down      Stop Docker containers"
	@echo "  make docker-restart   Restart Docker containers"
	@echo "  make docker-logs      View Docker logs"
	@echo ""
	@echo "$(YELLOW)🚀 Deployment:$(NC)"
	@echo "  make deploy-local     Deploy locally"
	@echo "  make deploy-docker    Deploy with Docker"
	@echo "  make deploy-ec2       Deploy to EC2"
	@echo "  make deploy-render    Deploy to Render"
	@echo ""
	@echo "$(YELLOW)🧪 Testing & Monitoring:$(NC)"
	@echo "  make test             Run all tests"
	@echo "  make health           Check service health"
	@echo "  make monitor          Monitor resource usage"
	@echo ""
	@echo "$(YELLOW)🧹 Maintenance:$(NC)"
	@echo "  make clean            Clean all build artifacts"
	@echo "  make clean-docker     Clean Docker artifacts"
	@echo "  make clean-models     Clean Rasa models and cache"
	@echo "  make update           Update and rebuild everything"
	@echo ""
	@echo "$(YELLOW)⚙️  Setup:$(NC)"
	@echo "  make setup-env        Setup environment files"
	@echo "  make setup-ec2        Setup EC2 instance"

## Installation Commands
install:
	@echo "$(GREEN)📦 Installing all dependencies...$(NC)"
	npm run install:all

install-backend:
	@echo "$(GREEN)📦 Installing backend dependencies...$(NC)"
	npm run install:backend

install-rasa:
	@echo "$(GREEN)📦 Installing Rasa dependencies...$(NC)"
	npm run install:rasa

## Development Commands
dev:
	@echo "$(GREEN)🔧 Starting development environment...$(NC)"
	npm run dev

dev-backend:
	@echo "$(GREEN)🔧 Starting backend development server...$(NC)"
	npm run dev:backend

dev-rasa:
	@echo "$(GREEN)🔧 Starting Rasa development server...$(NC)"
	npm run dev:rasa

dev-actions:
	@echo "$(GREEN)🔧 Starting Rasa actions server...$(NC)"
	npm run dev:actions

## Training Commands
train:
	@echo "$(GREEN)🎯 Training production Rasa model...$(NC)"
	npm run train

train-minimal:
	@echo "$(GREEN)🎯 Training minimal Rasa model...$(NC)"
	npm run train:minimal

## Docker Commands
docker-build:
	@echo "$(GREEN)🐳 Building Docker containers...$(NC)"
	npm run docker:build

docker-up:
	@echo "$(GREEN)🐳 Starting Docker containers...$(NC)"
	npm run docker:up

docker-down:
	@echo "$(GREEN)🐳 Stopping Docker containers...$(NC)"
	npm run docker:down

docker-restart:
	@echo "$(GREEN)🐳 Restarting Docker containers...$(NC)"
	npm run docker:restart

docker-logs:
	@echo "$(GREEN)🐳 Viewing Docker logs...$(NC)"
	npm run docker:logs

## Deployment Commands
deploy-local:
	@echo "$(GREEN)🚀 Deploying locally...$(NC)"
	./deploy.sh local

deploy-docker:
	@echo "$(GREEN)🚀 Deploying with Docker...$(NC)"
	./deploy.sh docker

deploy-ec2:
	@echo "$(GREEN)🚀 Deploying to EC2...$(NC)"
	./deploy.sh ec2

deploy-render:
	@echo "$(GREEN)🚀 Deploying to Render...$(NC)"
	./deploy.sh render

## Testing & Monitoring Commands
test:
	@echo "$(GREEN)🧪 Running all tests...$(NC)"
	npm run test

health:
	@echo "$(GREEN)🔍 Checking service health...$(NC)"
	npm run health

monitor:
	@echo "$(GREEN)📊 Monitoring resource usage...$(NC)"
	npm run monitor

## Maintenance Commands
clean:
	@echo "$(GREEN)🧹 Cleaning all build artifacts...$(NC)"
	npm run clean

clean-docker:
	@echo "$(GREEN)🧹 Cleaning Docker artifacts...$(NC)"
	npm run clean:docker

clean-models:
	@echo "$(GREEN)🧹 Cleaning Rasa models and cache...$(NC)"
	npm run clean:models

update:
	@echo "$(GREEN)🔄 Updating and rebuilding everything...$(NC)"
	npm run update

## Setup Commands
setup-env:
	@echo "$(GREEN)⚙️  Setting up environment files...$(NC)"
	npm run setup:env

setup-ec2:
	@echo "$(GREEN)⚙️  Setting up EC2 instance...$(NC)"
	npm run setup:ec2

## Quick deployment shortcuts
quick-local: install train deploy-local
	@echo "$(GREEN)✅ Quick local deployment completed!$(NC)"

quick-docker: install train docker-build docker-up
	@echo "$(GREEN)✅ Quick Docker deployment completed!$(NC)"

quick-production: install train deploy-ec2
	@echo "$(GREEN)✅ Quick production deployment completed!$(NC)"

## Development workflow
dev-workflow: setup-env install train dev
	@echo "$(GREEN)✅ Development workflow completed!$(NC)"

## Production workflow
prod-workflow: setup-env install train deploy-docker health
	@echo "$(GREEN)✅ Production workflow completed!$(NC)"

## Full deployment test
full-test: clean install train test deploy-docker health monitor
	@echo "$(GREEN)✅ Full deployment test completed!$(NC)"