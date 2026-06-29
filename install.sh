#!/bin/bash
# PSM Enterprise — One-click installer (Linux/macOS)
# - Creates .env if missing
# - Builds & starts Postgres + Backend (C#/.NET) + Frontend (Nginx) via Docker
# - Database + schema + initial Admin user are created automatically on backend startup
# - Waits for the app to become healthy
# - Opens the app in your default browser
set -e
cd "$(dirname "$0")"

echo "🚀 PSM Enterprise — نصب و اجرای خودکار"
echo ""

if ! command -v docker &> /dev/null; then
    echo "❌ Docker یافت نشد. لطفاً Docker و Docker Compose را نصب کنید: https://docs.docker.com/get-docker/"
    exit 1
fi

if [ ! -f .env ]; then
    cp .env.example .env
    echo "✓ فایل .env از .env.example ساخته شد"
fi

# Load FRONTEND_PORT (default 80) for the health-check / browser URL below.
FRONTEND_PORT=$(grep -E '^FRONTEND_PORT=' .env | cut -d '=' -f2)
FRONTEND_PORT=${FRONTEND_PORT:-80}
URL="http://localhost"
[ "$FRONTEND_PORT" != "80" ] && URL="http://localhost:${FRONTEND_PORT}"

echo "📦 ساخت و راه‌اندازی کانتینرها (دیتابیس، بک‌اند، فرانت‌اند)..."
docker compose up -d --build

echo "⏳ در انتظار آماده شدن سیستم..."
READY=0
for i in $(seq 1 60); do
    if curl -fs "${URL}/health" > /dev/null 2>&1; then
        READY=1
        break
    fi
    sleep 2
done

echo ""
if [ "$READY" = "1" ]; then
    echo "✅ سیستم با موفقیت بالا آمد!"
else
    echo "⚠️  سیستم هنوز پاسخ نمی‌دهد؛ ممکن است نیاز به کمی زمان بیشتر داشته باشد."
    echo "    بررسی وضعیت: docker compose ps    |    لاگ‌ها: docker compose logs -f backend"
fi
echo ""
echo "🌐 آدرس برنامه : ${URL}"
echo "📡 آدرس API    : http://localhost:${BACKEND_PORT:-3000}"
echo "👤 نام کاربری  : admin"
echo "🔑 رمز عبور    : Admin@1234 (اگر در .env تغییر نداده باشید)"
echo ""

# Open the browser automatically.
if command -v xdg-open &> /dev/null; then
    xdg-open "$URL" > /dev/null 2>&1 &
elif command -v open &> /dev/null; then
    open "$URL" > /dev/null 2>&1 &
elif command -v wslview &> /dev/null; then
    wslview "$URL" > /dev/null 2>&1 &
else
    echo "ℹ️  مرورگر را به صورت دستی باز کنید: ${URL}"
fi
