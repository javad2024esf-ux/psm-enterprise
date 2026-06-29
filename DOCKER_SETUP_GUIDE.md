# PSM Enterprise Docker Compose Setup & Troubleshooting Guide

## Quick Start (Fixes Your Current Issue)

### The Problem
Your backend container is crashing with:
```
System.InvalidOperationException: متغیر محیطی JWT_SECRET تنظیم نشده یا کمتر از ۳۲ کاراکتر است.
```

**Translation:** "Environment variable JWT_SECRET is not set or is less than 32 characters."

### The Solution (3 Steps)

#### 1. **Verify the .env File Exists**
```bash
# In your project root directory
ls -la .env
```

You should see a `.env` file. If not, it was just created for you. This file contains all required environment variables.

#### 2. **Key Environment Variables Required**

| Variable | Purpose | Minimum Length | Required |
|----------|---------|-----------------|----------|
| `JWT_SECRET` | Backend JWT token signing | 32 chars | ✅ YES |
| `PG_PASSWORD` | PostgreSQL password | Any | ✅ YES |
| `PG_DATABASE` | Database name | Any | ✅ YES |
| `PG_USER` | DB username | Any | ✅ YES |
| `CORS_ORIGINS` | Frontend origins | Any | ✅ YES |
| `ANTHROPIC_API_KEY` | Claude API (optional) | - | ❌ NO |

#### 3. **Start Docker Compose**

**On Windows (PowerShell):**
```powershell
# Stop old containers
docker compose down

# Verify .env is present
Get-Content .env

# Start fresh
docker compose up
```

**On macOS/Linux:**
```bash
docker compose down
cat .env  # verify it exists
docker compose up
```

---

## Understanding the Docker Compose Setup

### Container Architecture

```
Frontend (Nginx)
├─ Port: 80 (configurable via FRONTEND_PORT)
├─ Serves: React app + API proxy
└─ Depends on: Backend

Backend (C# ASP.NET Core)
├─ Port: 3000 (internal) → 3131 (external localhost)
├─ Framework: .NET 8 with Dapper ORM
├─ Auth: JWT tokens
└─ Depends on: PostgreSQL (healthy)

PostgreSQL Database
├─ Port: 5432 (internal) → 5433 (external localhost)
├─ Engine: PostgreSQL 16 Alpine
├─ Init Scripts: Auto-runs migrations
└─ Health Check: pg_isready (10 retries, 5s interval)
```

### Environment Variable Flow

1. **Docker Compose reads `.env` file** at startup
2. **Variables are passed to containers** via `environment:` section
3. **Backend (`Program.cs`) validates** required variables at line 32
4. **Database connection string** is built from `PG_*` variables
5. **JWT authentication** uses `JWT_SECRET` for token signing

---

## Common Issues & Fixes

### Issue 1: Backend Exits Immediately (Your Current Issue)

**Symptom:**
```
backend-1 exited with code 139 (restarting)
Unhandled exception. System.InvalidOperationException: متغیر محیطی JWT_SECRET...
```

**Cause:** `.env` file missing or `JWT_SECRET` is empty/too short.

**Fix:**
```bash
# Ensure .env exists
ls -la .env

# Check JWT_SECRET value
grep JWT_SECRET .env

# Should output: JWT_SECRET=aY7kL9pQmZ3xR2wN4sB1cD5eF8gH6jK0PoL2MqR5tU8vX9yZ3aB6cD9eF2gH5jK8
# (or your custom 32+ character value)

# If empty or too short, regenerate:
openssl rand -hex 32  # generates 64-char random hex string
```

### Issue 2: Database Connection Fails

**Symptom:**
```
Backend error: Unable to connect to PostgreSQL at db:5432
```

**Cause:** `PG_PASSWORD` not matching or database not initialized.

**Fix:**
```bash
# 1. Check docker-compose warnings
docker compose logs db

# 2. Verify credentials match
grep PG_ .env

# 3. Ensure database is healthy
docker compose ps  # check "STATUS" column

# 4. Force restart
docker compose restart db
```

### Issue 3: Frontend Can't Reach Backend

**Symptom:**
```
Frontend errors: CORS policy: No 'Access-Control-Allow-Origin' header
or
Failed to fetch from /api/...
```

**Cause:** 
- `CORS_ORIGINS` doesn't include frontend origin
- Backend not responding
- Nginx proxy misconfigured

**Fix:**
```bash
# 1. Check if backend is healthy
curl http://localhost:3131/health

# 2. Verify CORS_ORIGINS includes your frontend URL
grep CORS_ORIGINS .env

# 3. For localhost development:
CORS_ORIGINS=http://localhost,http://localhost:80,http://localhost:3000,http://127.0.0.1

# 4. Restart backend after CORS change
docker compose restart backend
```

### Issue 4: Nginx Can't Read Config (Read-Only Filesystem)

**Symptom:**
```
/docker-entrypoint.sh: can not modify /etc/nginx/conf.d/default.conf (read-only file system?)
```

**This is normal.** Nginx handles this gracefully—it skips the modification but continues.

### Issue 5: Containers Won't Start (Port Conflict)

**Symptom:**
```
Error: bind: address already in use
```

**Fix:**
```bash
# Find what's using the port (Windows PowerShell)
Get-NetTCPConnection -LocalPort 80 | Select-Object OwnerProcess

# Or (macOS/Linux)
sudo lsof -i :80

# Either stop the service or change FRONTEND_PORT in .env
FRONTEND_PORT=8080  # use port 8080 instead
```

---

## Production Deployment Checklist

### Security Requirements

- [ ] Change `JWT_SECRET` to a new secure random value (minimum 32 characters)
  ```bash
  # Generate a new secret
  openssl rand -hex 32
  ```

- [ ] Change `PG_PASSWORD` to a strong password (uppercase, lowercase, numbers, symbols)

- [ ] Change `ADMIN_SEED_PASSWORD` and rotate after first login

- [ ] Set `ANTHROPIC_API_KEY` only if using AI features

- [ ] Update `CORS_ORIGINS` to your production domain:
  ```
  CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
  ```

- [ ] Set `AI_ENABLED=true` only if you have ANTHROPIC_API_KEY configured

- [ ] Store `.env` in a secrets manager (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault)

### Docker Compose for Production

Consider using `docker-compose.prod.yml`:
```bash
docker compose -f docker-compose.prod.yml up -d
```

---

## Debugging Commands

### View Logs
```bash
# All containers
docker compose logs -f

# Specific service
docker compose logs -f backend
docker compose logs -f db
docker compose logs -f frontend

# Last 50 lines
docker compose logs -f --tail=50 backend
```

### Check Service Health
```bash
# Status of all containers
docker compose ps

# Detailed status
docker compose ps --no-trunc

# Health check results
docker compose exec db pg_isready -U psm_user -d psm
```

### Connect to Database Directly
```bash
# From host machine (if port exposed)
psql -h localhost -p 5433 -U psm_user -d psm

# From inside container
docker compose exec db psql -U psm_user -d psm
```

### Test Backend API
```bash
# Health check
curl http://localhost:3131/health

# List endpoints
curl http://localhost:3131/swagger/index.html
```

### Rebuild Containers
```bash
# Rebuild all images (useful after code changes)
docker compose build

# Rebuild specific service
docker compose build backend

# Build without cache
docker compose build --no-cache
```

### Full Restart (Nuclear Option)
```bash
# Stop all containers
docker compose down

# Remove volumes (⚠️ DELETES DATABASE)
docker compose down -v

# Remove images too
docker compose down --rmi all

# Restart
docker compose up
```

---

## File Permissions & Data Persistence

### Volumes
```yaml
psm_pgdata:       # PostgreSQL data files
psm_data:         # Application data directory
psm_dataprotection:  # .NET Core Data Protection keys
```

All volumes persist data between container restarts. To reset:
```bash
docker compose down -v  # ⚠️ Removes all data
```

### Data Directory (`DATA_DIR=/app/data`)
Backend stores application files here. Ensure directory permissions:
```bash
# Inside container (backend already handles this)
# But if needed manually:
docker compose exec backend chmod 700 /app/data
```

---

## Environment Variable Examples

### Minimal Development Setup
```env
JWT_SECRET=your-minimum-32-character-secure-random-key-here-xyz123
PG_PASSWORD=dev_password
CORS_ORIGINS=http://localhost,http://localhost:80
```

### Full Development Setup
```env
JWT_SECRET=aY7kL9pQmZ3xR2wN4sB1cD5eF8gH6jK0PoL2MqR5tU8vX9yZ3aB6cD9eF2gH5jK8
PG_PASSWORD=dev_postgres_password
PG_DATABASE=psm_dev
PG_USER=psm_user
CORS_ORIGINS=http://localhost,http://localhost:80,http://localhost:3000,http://127.0.0.1
ADMIN_SEED_USERNAME=admin
ADMIN_SEED_PASSWORD=Admin@Dev#2026
AI_ENABLED=false
LOG_LEVEL=debug
```

### Production Setup (Template)
```env
JWT_SECRET=[use: openssl rand -hex 32]
PG_PASSWORD=[strong random password]
PG_DATABASE=psm_prod
PG_USER=psm_prod_user
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
ADMIN_SEED_USERNAME=admin
ADMIN_SEED_PASSWORD=[strong random password, change after first login]
AI_ENABLED=true
ANTHROPIC_API_KEY=sk-ant-[your-key]
LOG_LEVEL=warning
```

---

## Next Steps

1. **Verify `.env` is in place:**
   ```bash
   ls -la .env
   ```

2. **Check JWT_SECRET is valid:**
   ```bash
   grep JWT_SECRET .env
   ```

3. **Start Docker Compose:**
   ```bash
   docker compose down  # clean up
   docker compose up    # start fresh
   ```

4. **Monitor logs:**
   ```bash
   docker compose logs -f
   ```

5. **Test the application:**
   - Frontend: http://localhost
   - Backend API: http://localhost:3131
   - Database: localhost:5433 (psql client required)

---

## Support

If you encounter issues:

1. **Check logs first:** `docker compose logs -f`
2. **Verify .env file:** `cat .env | grep -i secret`
3. **Restart from scratch:** `docker compose down && docker compose up`
4. **Check Docker version:** `docker --version && docker compose version`

---

**Last Updated:** June 28, 2026  
**Project:** PSM Enterprise  
**Environment:** Docker Compose with C# Backend & React Frontend
