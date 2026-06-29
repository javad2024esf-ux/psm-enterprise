# PSM Enterprise → Railway: Quick Action Guide

## 🎯 The Problem (In 30 Seconds)

Your deployment failed because:
- **Your Setup**: Uses `docker-compose.prod.yml` with 4 services (Frontend, Backend, PostgreSQL, Redis)
- **Railway's Limitation**: Doesn't support `docker compose` as a build/start command
- **The Error**: `railway.json` was misconfigured to use a "dockerfile" builder

---

## ✅ The Solution (In 3 Steps)

### Step 1: Commit Code to GitHub
```bash
# Make sure your code is in a Git repository (not in a zip file)
cd your-psm-enterprise-repo
git add .
git commit -m "PSM Enterprise - Ready for Railway deployment"
git push origin main
```

### Step 2: Create Railway Account & Project
1. Go to **railway.app**
2. Sign in with GitHub
3. Click "New Project" → "Deploy from GitHub repo" → select your repo

### Step 3: Add & Configure Services
Railway will guide you through adding services. Follow this order:

**Add PostgreSQL Database:**
```
Add Service → Database → PostgreSQL
(Railway creates it automatically)
```

**Add Redis Cache:**
```
Add Service → Database → Redis
(Railway creates it automatically)
```

**Add Backend Service:**
```
Add Service → GitHub Repo (same repo)
Configuration:
  - Dockerfile: Dockerfile.backend-csharp
  - Environment Variables:
    PG_HOST: <auto-filled from Postgres service>
    PG_PORT: 5432
    PG_DATABASE: railway
    PG_USER: postgres
    PG_PASSWORD: <auto-filled from Postgres service>
    REDIS_CONNECTION: <auto-filled from Redis service>
    JWT_SECRET: <generate using: openssl rand -hex 32>
    CORS_ORIGINS: https://your-frontend.railway.app
    ADMIN_SEED_USERNAME: admin
    ADMIN_SEED_PASSWORD: <strong-password>
    PSM_LICENSE_SECRET: <random-string>
```

**Add Frontend Service:**
```
Add Service → GitHub Repo (same repo)
Configuration:
  - Dockerfile: Dockerfile.frontend
  - Build Args: VITE_API_URL=/api
  - Port Mapping: 80:80
```

**Link Services Together:**
```
Project → Networking → Link Services
- Frontend needs to reach Backend
- Backend needs to reach PostgreSQL
- Backend needs to reach Redis
```

---

## 📊 What You Get

| Aspect | Benefit |
|--------|---------|
| **Automatic Scaling** | Each service scales independently |
| **Built-in Monitoring** | Logs, metrics, health checks included |
| **Database Backups** | PostgreSQL auto-backup every day |
| **HTTPS** | Automatic SSL/TLS certificates |
| **Custom Domain** | Add your own domain easily |
| **Cost Transparency** | Pay only for what you use |

---

## 🔐 Critical Security Steps

1. **Generate JWT_SECRET** (must be 64+ characters):
   ```bash
   openssl rand -hex 32
   ```
   Copy this random string and paste it into Railway as `JWT_SECRET`

2. **Strong Admin Password**:
   Don't use "admin123" — use something like `Tr0p!cal$unset#2024`

3. **Change Admin Password After Login**:
   After first login, go to Settings → Change Password immediately

4. **CORS Configuration**:
   Set `CORS_ORIGINS` to exactly your frontend domain(s):
   ```
   https://your-app.railway.app
   https://www.yourdomain.com
   ```

---

## 🚀 Testing After Deployment

Once everything deploys:

1. **Access your app:**
   ```
   https://your-frontend.railway.app
   ```

2. **Login with admin credentials:**
   - Username: `admin`
   - Password: (what you set in `ADMIN_SEED_PASSWORD`)

3. **Check features work:**
   - ✅ Dashboard loads
   - ✅ Can create a new HAZOP study
   - ✅ Can upload files
   - ✅ Database is working (data persists)
   - ✅ AI features work (if API key added)

4. **Check logs if something breaks:**
   - Railway Dashboard → Service → Logs
   - Look for error messages with timestamps

---

## 📁 Files Provided

Your outputs folder contains:

1. **railway.json** — Base configuration (reference only)
2. **RAILWAY_FIX_SUMMARY.md** — Issue analysis + solution overview
3. **RAILWAY_DEPLOYMENT_GUIDE.md** — Detailed step-by-step guide (15+ pages)
4. **RAILWAY_CLI_GUIDE.md** — Command-line reference if you prefer CLI

**Read RAILWAY_DEPLOYMENT_GUIDE.md for complete details.**

---

## ⚠️ Common Issues & Quick Fixes

### "Build failed - no Dockerfile found"
✅ **Fix**: Verify Dockerfile path in service settings (case-sensitive)
- Backend: `Dockerfile.backend-csharp`
- Frontend: `Dockerfile.frontend`

### "Connection refused" or "Cannot reach backend"
✅ **Fix**: Check services are linked in Networking section

### "Database error - cannot connect"
✅ **Fix**: 
1. Copy connection string from PostgreSQL service
2. Set all `PG_*` variables correctly
3. Restart backend service

### "502 Bad Gateway"
✅ **Fix**: Check backend logs, verify health check endpoint works

### "Build timeout"
✅ **Fix**: NuGet timeout already increased to 300s in Dockerfile (handled)

---

## 📞 Need Help?

1. **Check Logs First**: Railway Dashboard → Service → Logs (most errors are visible)
2. **Read the Full Guide**: RAILWAY_DEPLOYMENT_GUIDE.md has 30+ troubleshooting tips
3. **Railway Docs**: https://docs.railway.app
4. **Test Locally**: Run `docker-compose -f docker-compose.prod.yml up` to test before deploying

---

## ✨ Next: Advanced Options (Optional)

After getting it working:

- Add custom domain
- Set up GitHub auto-deploy on push
- Configure backup schedules
- Set up monitoring alerts
- Scale up resources if needed

**All documented in RAILWAY_DEPLOYMENT_GUIDE.md**

---

## 📋 Checklist

- [ ] Code committed to GitHub (not zip)
- [ ] Railway account created
- [ ] PostgreSQL service added
- [ ] Redis service added
- [ ] Backend service configured with env vars
- [ ] Frontend service configured
- [ ] Services linked together
- [ ] Deployment completed without errors
- [ ] Application accessible at frontend URL
- [ ] Can login with admin credentials
- [ ] Admin password changed
- [ ] Database migrations ran (check in logs)

**That's it! You're ready to deploy!** 🚀

---

## 🎓 Learning Path

1. **Start here** ← You are here
2. **Read**: RAILWAY_DEPLOYMENT_GUIDE.md (detailed walkthrough)
3. **Execute**: Follow the step-by-step guide
4. **Monitor**: Watch logs in Railway Dashboard
5. **Verify**: Test the application
6. **Scale** (optional): Increase resources if needed

---

**Status**: ✅ You have everything needed to deploy successfully!

All files are in your outputs folder. Print this guide, follow it step-by-step, and you'll have PSM Enterprise running on Railway in 20 minutes. 

**Questions?** Check RAILWAY_DEPLOYMENT_GUIDE.md first — it has answers to 30+ questions with code examples.

Good luck! 🎉
