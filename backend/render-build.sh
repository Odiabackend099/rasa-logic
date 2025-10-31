#!/bin/bash
# Render build script for backend
set -e

echo "Building Backend API..."
cd backend
npm ci --production=false
echo "✅ Backend build complete"

