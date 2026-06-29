#!/bin/bash
# PSM Enterprise Docker Setup Verification Script
# Run this to verify your environment is properly configured
# Usage: bash ./verify-setup.sh or chmod +x verify-setup.sh && ./verify-setup.sh

set +e  # Don't exit on errors

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  PSM Enterprise Docker Setup Verification${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if .env file exists
echo -e "${YELLOW}[1] Checking .env file...${NC}"
if [ -f ".env" ]; then
    echo -e "    ${GREEN}✓ .env file found${NC}"
    ENV_EXISTS=true
    # Load environment variables
    set -a
    source .env
    set +a
else
    echo -e "    ${RED}✗ .env file NOT found${NC}"
    ENV_EXISTS=false
fi

echo ""
echo -e "${YELLOW}[2] Checking required environment variables...${NC}"

# Check JWT_SECRET
if [ -n "$JWT_SECRET" ]; then
    SECRET_LENGTH=${#JWT_SECRET}
    if [ $SECRET_LENGTH -ge 32 ]; then
        echo -e "    ${GREEN}✓ JWT_SECRET is set and minimum 32 characters ($SECRET_LENGTH chars)${NC}"
    else
        echo -e "    ${RED}✗ JWT_SECRET is too short: $SECRET_LENGTH characters (minimum: 32)${NC}"
    fi
else
    echo -e "    ${RED}✗ JWT_SECRET is NOT SET${NC}"
fi

# Check PG_PASSWORD
if [ -n "$PG_PASSWORD" ]; then
    echo -e "    ${GREEN}✓ PG_PASSWORD is set${NC}"
else
    echo -e "    ${RED}✗ PG_PASSWORD is NOT SET${NC}"
fi

# Check CORS_ORIGINS
if [ -n "$CORS_ORIGINS" ]; then
    echo -e "    ${GREEN}✓ CORS_ORIGINS is set${NC}"
else
    echo -e "    ${RED}✗ CORS_ORIGINS is NOT SET${NC}"
fi

echo ""
echo -e "${YELLOW}[3] Checking Docker installation...${NC}"

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version 2>/dev/null)
    echo -e "    ${GREEN}✓ Docker installed: $DOCKER_VERSION${NC}"
else
    echo -e "    ${RED}✗ Docker NOT installed or not in PATH${NC}"
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    COMPOSE_VERSION=$(docker compose version 2>/dev/null || docker-compose --version 2>/dev/null)
    echo -e "    ${GREEN}✓ Docker Compose installed: $COMPOSE_VERSION${NC}"
else
    echo -e "    ${RED}✗ Docker Compose NOT installed${NC}"
fi

echo ""
echo -e "${YELLOW}[4] Checking current Docker containers...${NC}"
if command -v docker &> /dev/null; then
    CONTAINERS=$(docker compose ps 2>/dev/null)
    if [ -n "$CONTAINERS" ]; then
        echo -e "    ${CYAN}Current containers:${NC}"
        docker compose ps --format "table {{.Service}}\t{{.Status}}" 2>/dev/null
    else
        echo -e "    ${GRAY}No containers running${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}[5] Port availability check...${NC}"

# Check port 80
if lsof -Pi :80 -sTCP:LISTEN -t &> /dev/null; then
    PORT_PROCESS=$(lsof -i :80 | grep LISTEN | awk '{print $1}')
    echo -e "    ${YELLOW}⚠ Port 80 is IN USE ($PORT_PROCESS)${NC}"
else
    echo -e "    ${GREEN}✓ Port 80 is available${NC}"
fi

# Check port 3131
if lsof -Pi :3131 -sTCP:LISTEN -t &> /dev/null; then
    echo -e "    ${YELLOW}⚠ Port 3131 is IN USE (backend)${NC}"
else
    echo -e "    ${GREEN}✓ Port 3131 is available (backend)${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

# Summary and recommendations
echo ""
echo -e "${GREEN}SUMMARY & NEXT STEPS:${NC}"
echo ""

READY_TO_START=true

if [ -z "$JWT_SECRET" ] || [ ${#JWT_SECRET} -lt 32 ]; then
    echo -e "${RED}❌ FIX REQUIRED: JWT_SECRET must be at least 32 characters${NC}"
    READY_TO_START=false
    echo -e "   ${CYAN}Generate new secret:${NC}"
    echo -e "   ${GRAY}$ openssl rand -hex 32${NC}"
    echo ""
fi

if [ -z "$PG_PASSWORD" ]; then
    echo -e "${RED}❌ FIX REQUIRED: PG_PASSWORD must be set in .env${NC}"
    READY_TO_START=false
    echo ""
fi

if [ "$READY_TO_START" = true ]; then
    echo -e "${GREEN}✓ All checks passed! Ready to start Docker Compose.${NC}"
    echo ""
    echo -e "${CYAN}Run these commands:${NC}"
    echo -e "  ${GRAY}$ docker compose down           # Clean up old containers${NC}"
    echo -e "  ${GRAY}$ docker compose up             # Start fresh deployment${NC}"
    echo -e "  ${GRAY}$ docker compose logs -f        # Monitor logs${NC}"
    echo ""
    echo -e "${CYAN}Access the application:${NC}"
    echo -e "  ${GRAY}Frontend:  http://localhost${NC}"
    echo -e "  ${GRAY}Backend:   http://localhost:3131${NC}"
    echo -e "  ${GRAY}Database:  localhost:5433${NC}"
else
    echo -e "${YELLOW}⚠ Please fix the issues above before starting Docker Compose${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
