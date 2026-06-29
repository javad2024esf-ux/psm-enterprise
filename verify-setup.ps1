#!/usr/bin/env pwsh
# PSM Enterprise Docker Setup Verification Script
# Run this to verify your environment is properly configured
# Usage: .\verify-setup.ps1

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  PSM Enterprise Docker Setup Verification" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if .env file exists
Write-Host "[1] Checking .env file..." -ForegroundColor Yellow
if (Test-Path ".env") {
    Write-Host "    ✓ .env file found" -ForegroundColor Green
    $envExists = $true
} else {
    Write-Host "    ✗ .env file NOT found" -ForegroundColor Red
    $envExists = $false
}

# Load .env file if it exists
if ($envExists) {
    $envContent = Get-Content ".env" -Raw
    $envVars = @{}
    
    foreach ($line in $envContent -split "`n") {
        if ($line -match "^([^=]+)=(.*)$") {
            $envVars[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
}

Write-Host ""
Write-Host "[2] Checking required environment variables..." -ForegroundColor Yellow

# Check JWT_SECRET
if ($envVars.ContainsKey("JWT_SECRET")) {
    $jwtSecret = $envVars["JWT_SECRET"]
    if ($jwtSecret.Length -ge 32) {
        Write-Host "    ✓ JWT_SECRET is set and ✓ minimum 32 characters ($($jwtSecret.Length) chars)" -ForegroundColor Green
    } else {
        Write-Host "    ✗ JWT_SECRET is too short: $($jwtSecret.Length) characters (minimum: 32)" -ForegroundColor Red
    }
} else {
    Write-Host "    ✗ JWT_SECRET is NOT SET" -ForegroundColor Red
}

# Check PG_PASSWORD
if ($envVars.ContainsKey("PG_PASSWORD") -and $envVars["PG_PASSWORD"]) {
    Write-Host "    ✓ PG_PASSWORD is set" -ForegroundColor Green
} else {
    Write-Host "    ✗ PG_PASSWORD is NOT SET" -ForegroundColor Red
}

# Check CORS_ORIGINS
if ($envVars.ContainsKey("CORS_ORIGINS") -and $envVars["CORS_ORIGINS"]) {
    Write-Host "    ✓ CORS_ORIGINS is set" -ForegroundColor Green
} else {
    Write-Host "    ✗ CORS_ORIGINS is NOT SET" -ForegroundColor Red
}

Write-Host ""
Write-Host "[3] Checking Docker installation..." -ForegroundColor Yellow

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "    ✓ Docker installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Docker NOT installed or not in PATH" -ForegroundColor Red
}

# Check Docker Compose
try {
    $composeVersion = docker compose version
    Write-Host "    ✓ Docker Compose installed: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "    ✗ Docker Compose NOT installed" -ForegroundColor Red
}

Write-Host ""
Write-Host "[4] Checking current Docker containers..." -ForegroundColor Yellow
try {
    $containers = docker compose ps
    if ($containers) {
        Write-Host "    Current containers:" -ForegroundColor Cyan
        docker compose ps --format "table {{.Service}}\t{{.Status}}"
    } else {
        Write-Host "    No containers running" -ForegroundColor Gray
    }
} catch {
    Write-Host "    ✗ Unable to check containers" -ForegroundColor Red
}

Write-Host ""
Write-Host "[5] Port availability check..." -ForegroundColor Yellow

# Check port 80 (frontend)
try {
    $port80 = Get-NetTCPConnection -LocalPort 80 -ErrorAction SilentlyContinue
    if ($port80) {
        Write-Host "    ⚠ Port 80 is IN USE" -ForegroundColor Yellow
        Write-Host "      Process: $($port80.OwnerProcess)" -ForegroundColor Gray
    } else {
        Write-Host "    ✓ Port 80 is available" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✓ Port 80 is available" -ForegroundColor Green
}

# Check port 3131 (backend)
try {
    $port3131 = Get-NetTCPConnection -LocalPort 3131 -ErrorAction SilentlyContinue
    if ($port3131) {
        Write-Host "    ⚠ Port 3131 is IN USE (backend)" -ForegroundColor Yellow
    } else {
        Write-Host "    ✓ Port 3131 is available (backend)" -ForegroundColor Green
    }
} catch {
    Write-Host "    ✓ Port 3131 is available (backend)" -ForegroundColor Green
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

# Summary and recommendations
Write-Host ""
Write-Host "SUMMARY & NEXT STEPS:" -ForegroundColor Green
Write-Host ""

$readyToStart = $true

if ($envVars["JWT_SECRET"].Length -lt 32) {
    Write-Host "❌ FIX REQUIRED: JWT_SECRET must be at least 32 characters" -ForegroundColor Red
    $readyToStart = $false
    Write-Host "   Generate new secret:" -ForegroundColor Cyan
    Write-Host "   > openssl rand -hex 32" -ForegroundColor Gray
    Write-Host ""
}

if (-not $envVars["PG_PASSWORD"]) {
    Write-Host "❌ FIX REQUIRED: PG_PASSWORD must be set in .env" -ForegroundColor Red
    $readyToStart = $false
    Write-Host ""
}

if ($readyToStart) {
    Write-Host "✓ All checks passed! Ready to start Docker Compose." -ForegroundColor Green
    Write-Host ""
    Write-Host "Run these commands:" -ForegroundColor Cyan
    Write-Host '  > docker compose down           # Clean up old containers' -ForegroundColor Gray
    Write-Host '  > docker compose up             # Start fresh deployment' -ForegroundColor Gray
    Write-Host '  > docker compose logs -f        # Monitor logs' -ForegroundColor Gray
    Write-Host ""
    Write-Host "Access the application:" -ForegroundColor Cyan
    Write-Host "  Frontend:  http://localhost" -ForegroundColor Gray
    Write-Host "  Backend:   http://localhost:3131" -ForegroundColor Gray
    Write-Host "  Database:  localhost:5433" -ForegroundColor Gray
} else {
    Write-Host "⚠ Please fix the issues above before starting Docker Compose" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
