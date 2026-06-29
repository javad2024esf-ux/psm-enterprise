# PSM Enterprise - Docker Compose Quick Reference

## Essential Commands

### Start & Stop
```bash
# Start all containers
docker compose up

# Start in background (detached mode)
docker compose up -d

# Start specific service
docker compose up -d backend

# Stop all containers (keeps data)
docker compose stop

# Stop and remove containers
docker compose down

# Remove everything including volumes (⚠️ DELETES DATA)
docker compose down -v
```

### View Status & Logs
```bash
# Show running containers and status
docker compose ps

# Show detailed container info
docker compose ps --no-trunc

# View all logs (follow in real-time)
docker compose logs -f

# View logs for specific service
docker compose logs -f backend
docker compose logs -f db
docker compose logs -f frontend

# View last 50 lines
docker compose logs -f --tail=50 backend

# View logs with timestamps
docker compose logs -f --timestamps
```

### Execute Commands
```bash
# Run shell command in container
docker compose exec backend bash

# Connect to PostgreSQL database
docker compose exec db psql -U psm_user -d psm

# Check PostgreSQL is ready
docker compose exec db pg_isready -U psm_user -d psm

# List files in backend container
docker compose exec backend ls -la /app

# View backend logs from inside container
docker compose exec backend cat /var/log/psm/app.log
```

### Rebuild & Restart
```bash
# Rebuild images from Dockerfiles
docker compose build

# Build without using cache
docker compose build --no-cache

# Rebuild specific service
docker compose build backend

# Rebuild and restart
docker compose up --build

# Rebuild everything from scratch
docker compose build --no-cache && docker compose up
```

### Restart Services
```bash
# Restart all services
docker compose restart

# Restart specific service
docker compose restart backend
docker compose restart db

# Restart and recreate containers
docker compose up -d --force-recreate
```

## Debugging

### Check Health Status
```bash
# PostgreSQL health
docker compose exec db pg_isready

# Backend API health
curl http://localhost:3131/health

# Frontend (check if nginx is responding)
curl -I http://localhost
```

### Network & Connectivity
```bash
# Check internal DNS (service discovery)
docker compose exec backend ping db

# Test database connection from backend
docker compose exec backend psql -h db -U psm_user -d psm -c "SELECT version();"
```

### Environment & Configuration
```bash
# View environment variables inside container
docker compose exec backend env | grep JWT
docker compose exec backend env | grep PG

# Check .env file in host
cat .env | grep JWT_SECRET

# Verify .env is being read
docker compose config  # Shows resolved config from .env
```

### Storage & Data
```bash
# List Docker volumes
docker volume ls | grep psm

# Inspect specific volume
docker volume inspect psm-enterprise_psm_pgdata

# View volume data location (host machine)
# Windows: %APPDATA%\Docker\volumes\psm-enterprise_psm_pgdata
# macOS/Linux: /var/lib/docker/volumes/psm-enterprise_psm_pgdata
```

## Common Troubleshooting

### Clear Everything & Start Fresh
```bash
# Nuclear option - removes all containers, volumes, and networks
docker compose down -v --remove-orphans

# Remove images too (force rebuild)
docker compose down -v --rmi all

# Start fresh
docker compose build --no-cache
docker compose up
```

### Fix Permission Issues
```bash
# Fix data directory permissions (inside backend container)
docker compose exec backend chmod -R 755 /app/data
docker compose exec backend chown -R root:root /app/data
```

### Monitor Resource Usage
```bash
# View CPU, memory, network for containers
docker compose stats

# View specific container stats
docker compose stats backend

# Stop the stats view: Ctrl+C
```

### Clean Up Unused Resources
```bash
# Remove stopped containers
docker container prune

# Remove dangling images (untagged)
docker image prune

# Remove unused volumes
docker volume prune

# Remove everything unused (containers, images, volumes)
docker system prune -a --volumes
```

## Environment Variable Quick Edit

### View Current .env
```bash
cat .env
```

### Edit .env (macOS/Linux)
```bash
nano .env
# or
vim .env
```

### Edit .env (Windows PowerShell)
```powershell
notepad .env
```

### Apply .env Changes
```bash
# Most changes require restart
docker compose restart backend

# Some changes require rebuild
docker compose up --build

# Nuclear: full restart
docker compose down -v && docker compose up --build
```

## Docker Compose File References

### Main Files
- `docker-compose.yml` - Development configuration
- `docker-compose.prod.yml` - Production configuration
- `.env` - Environment variables (loaded automatically)

### Use Specific Compose File
```bash
# Use production config
docker compose -f docker-compose.prod.yml up

# Use multiple files (later overrides earlier)
docker compose -f docker-compose.yml -f docker-compose.prod.yml up
```

## Quick One-Liners

### Full Deployment from Scratch
```bash
docker compose down -v && docker compose up --build
```

### Rebuild and Deploy
```bash
docker compose build && docker compose up
```

### Stop Everything Gracefully
```bash
docker compose down
```

### View All Environment Variables Passed to Backend
```bash
docker compose exec backend env | sort
```

### Export Logs to File
```bash
docker compose logs > docker_logs.txt
```

### Monitor All Logs Live
```bash
docker compose logs -f --all
```

### Check Latest Errors
```bash
docker compose logs --tail=100 | grep -i error
```

## Windows PowerShell Specific

### Run Commands
```powershell
# Instead of: docker compose exec -it backend bash
docker compose exec backend powershell

# View logs with filtering
docker compose logs -f | Select-String "error" -ForegroundColor Red
```

### Generate JWT Secret
```powershell
# Using .NET Core (if installed)
[Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes((Get-Random -SetSeed (Get-Date).Ticks -Count 32 | ForEach-Object { [char]$_ } | Join-String)))

# Or use online tool: https://www.random.org/bytes/
```

## Performance Optimization

### Limit Resource Usage
Add to `docker-compose.yml` under backend service:
```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1024M
    reservations:
      cpus: '0.5'
      memory: 512M
```

### Use Build Cache Effectively
```bash
# Build with cache (faster)
docker compose build

# Build without cache (slower but fresh)
docker compose build --no-cache
```

## Useful Documentation

- Docker Compose Docs: https://docs.docker.com/compose/
- Docker CLI Reference: https://docs.docker.com/engine/reference/commandline/
- PSM Enterprise Docs: See DOCKER_SETUP_GUIDE.md in project root

---

**Quick Help:** `docker compose help` or `docker compose up --help`
