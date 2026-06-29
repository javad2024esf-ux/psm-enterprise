.PHONY: help up down logs health seed clean

help:
	@echo "PSM Enterprise - Docker Commands"
	@echo ""
	@echo "make up          - Start all services"
	@echo "make down        - Stop all services"
	@echo "make logs        - View container logs"
	@echo "make health      - Check service health"
	@echo "make seed        - Load demo data"
	@echo "make clean       - Remove all containers and volumes"
	@echo "make rebuild     - Rebuild images"

up:
	@bash startup.sh

down:
	docker compose down

logs:
	docker compose logs -f

health:
	@docker compose ps
	@echo ""
	@docker compose exec -T db pg_isready -U psm_user && echo "✓ Database OK" || echo "✗ Database Error"
	@docker compose exec -T backend curl -s http://localhost:3000/health > /dev/null && echo "✓ Backend OK" || echo "✗ Backend Error"

seed:
	docker compose --profile demo run --rm seed-demo

clean:
	docker compose down -v
	docker system prune -f

rebuild:
	docker compose build --no-cache
	docker compose up -d
