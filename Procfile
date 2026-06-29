# Railway.app Procfile
# Specify how to start the application

release: docker compose exec db psql -U psm_user -d psm -c "ALTER USER psm_user WITH PASSWORD 'secure_psm_password_2026_change_in_production';"
web: docker compose up
