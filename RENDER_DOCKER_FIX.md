# Render Docker Detection Fix

## Issue

Render was trying to use Docker instead of build commands, causing:
```
error: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```

## Solution

Updated `render.yaml` to:
1. Use `env` instead of `runtime` (correct Render syntax)
2. Add `rootDir` to specify working directory
3. Simplify build commands (remove redundant `cd` commands)

## Changes Made

### Backend Service
- Changed `runtime: node` → `env: node`
- Added `rootDir: backend`
- Build command simplified

### Rasa Services
- Changed `runtime: python` → `env: python`
- Added `rootDir: rasa-agent`
- Build commands updated to work from rootDir

## How Render Detects Docker

Render checks for:
1. `Dockerfile` in root → Uses Docker
2. `docker-compose.yml` → Uses Docker Compose
3. Build commands in `render.yaml` → Uses build commands

Since we have `render.yaml` with build commands, Render should use those instead of Docker.

## Verification

After deploying, check:
1. Build logs show Node.js/Python build commands
2. No Docker-related errors
3. Services start correctly

If issues persist:
1. Verify `render.yaml` is in repository root
2. Check service configuration in Render dashboard
3. Ensure no `Dockerfile` exists in repo

