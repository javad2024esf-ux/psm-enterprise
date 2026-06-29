@echo off
REM PSM Enterprise — One-click installer (Windows)
REM - Creates .env if missing
REM - Builds & starts Postgres + Backend (C#/.NET) + Frontend (Nginx) via Docker
REM - Database + schema + initial Admin user are created automatically on backend startup
REM - Waits for the app to become healthy, then opens it in your default browser

cd /d "%~dp0"
echo PSM Enterprise - Auto Install ^& Run
echo.

where docker >nul 2>nul
if errorlevel 1 (
    echo Docker not found. Install Docker Desktop: https://docs.docker.com/get-docker/
    pause
    exit /b 1
)

if not exist .env (
    copy .env.example .env >nul
    echo .env created from .env.example
)

set URL=http://localhost

echo Building and starting containers (database, backend, frontend)...
docker compose up -d --build

echo Waiting for the app to become ready...
set READY=0
for /l %%i in (1,1,60) do (
    curl -fs %URL%/health >nul 2>nul
    if not errorlevel 1 (
        set READY=1
        goto :done
    )
    timeout /t 2 /nobreak >nul
)
:done

echo.
if "%READY%"=="1" (
    echo App is up and running!
) else (
    echo App is not responding yet. Check: docker compose logs -f backend
)
echo.
echo Web UI : %URL%
echo API    : http://localhost:3000
echo User   : admin
echo Pass   : Admin@1234  (unless changed in .env)
echo.

start "" "%URL%"
