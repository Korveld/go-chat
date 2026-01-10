# Load environment variables from .env
include .env
export

# Database connection string
DB_URL=postgresql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

# Colors for output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

.PHONY: help install-migrate create-migration migrate-up migrate-down migrate-force migrate-version db-reset db-create db-drop run test

help: ## Show this help message
	@echo "$(GREEN)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*##"; } /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install-migrate: ## Install golang-migrate CLI tool
	@echo "$(GREEN)Installing golang-migrate...$(NC)"
	@which migrate > /dev/null || (echo "$(YELLOW)Installing migrate...$(NC)" && \
		go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest)
	@echo "$(GREEN)✓ migrate installed successfully$(NC)"

create-migration: ## Create a new migration file (usage: make create-migration name=add_users_table)
	@if [ -z "$(name)" ]; then \
		echo "$(RED)Error: name is required$(NC)"; \
		echo "Usage: make create-migration name=your_migration_name"; \
		exit 1; \
	fi
	@echo "$(GREEN)Creating migration: $(name)$(NC)"
	@migrate create -ext sql -dir migrations -seq $(name)
	@echo "$(GREEN)✓ Migration files created in migrations/$(NC)"

migrate-up: ## Run all up migrations
	@echo "$(GREEN)Running migrations up...$(NC)"
	@migrate -path migrations -database "$(DB_URL)" up
	@echo "$(GREEN)✓ Migrations applied successfully$(NC)"

migrate-down: ## Rollback last migration
	@echo "$(YELLOW)Rolling back last migration...$(NC)"
	@migrate -path migrations -database "$(DB_URL)" down 1
	@echo "$(GREEN)✓ Migration rolled back$(NC)"

migrate-down-all: ## Rollback all migrations
	@echo "$(RED)Rolling back ALL migrations...$(NC)"
	@read -p "Are you sure? This will drop all tables! (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		migrate -path migrations -database "$(DB_URL)" down -all; \
		echo "$(GREEN)✓ All migrations rolled back$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

migrate-force: ## Force set migration version (usage: make migrate-force version=1)
	@if [ -z "$(version)" ]; then \
		echo "$(RED)Error: version is required$(NC)"; \
		echo "Usage: make migrate-force version=1"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Forcing migration version to $(version)...$(NC)"
	@migrate -path migrations -database "$(DB_URL)" force $(version)
	@echo "$(GREEN)✓ Migration version set to $(version)$(NC)"

migrate-version: ## Show current migration version
	@echo "$(GREEN)Current migration version:$(NC)"
	@migrate -path migrations -database "$(DB_URL)" version

migrate-goto: ## Migrate to specific version (usage: make migrate-goto version=1)
	@if [ -z "$(version)" ]; then \
		echo "$(RED)Error: version is required$(NC)"; \
		echo "Usage: make migrate-goto version=1"; \
		exit 1; \
	fi
	@echo "$(GREEN)Migrating to version $(version)...$(NC)"
	@migrate -path migrations -database "$(DB_URL)" goto $(version)
	@echo "$(GREEN)✓ Migrated to version $(version)$(NC)"

db-create: ## Create database
	@echo "$(GREEN)Creating database $(DB_NAME)...$(NC)"
	@PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d postgres -c "CREATE DATABASE $(DB_NAME);" 2>/dev/null || echo "$(YELLOW)Database may already exist$(NC)"
	@echo "$(GREEN)✓ Database ready$(NC)"

db-drop: ## Drop database
	@echo "$(RED)Dropping database $(DB_NAME)...$(NC)"
	@read -p "Are you sure? This will delete all data! (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		PGPASSWORD=$(DB_PASSWORD) psql -h $(DB_HOST) -p $(DB_PORT) -U $(DB_USER) -d postgres -c "DROP DATABASE IF EXISTS $(DB_NAME);"; \
		echo "$(GREEN)✓ Database dropped$(NC)"; \
	else \
		echo "$(YELLOW)Cancelled$(NC)"; \
	fi

db-reset: db-drop db-create migrate-up ## Drop, create, and migrate database
	@echo "$(GREEN)✓ Database reset complete$(NC)"

db-seed: ## Seed database with sample data
	@echo "$(GREEN)Seeding database...$(NC)"
	@go run scripts/seed.go
	@echo "$(GREEN)✓ Database seeded$(NC)"

run: ## Run the application
	@echo "$(GREEN)Starting server...$(NC)"
	@go run main.go

build: ## Build the application
	@echo "$(GREEN)Building application...$(NC)"
	@go build -o bin/chat-server main.go
	@echo "$(GREEN)✓ Built to bin/chat-server$(NC)"

test: ## Run tests
	@echo "$(GREEN)Running tests...$(NC)"
	@go test -v ./...

clean: ## Clean build artifacts
	@echo "$(GREEN)Cleaning...$(NC)"
	@rm -rf bin/
	@echo "$(GREEN)✓ Cleaned$(NC)"

deps: ## Download dependencies
	@echo "$(GREEN)Downloading dependencies...$(NC)"
	@go mod download
	@go mod tidy
	@echo "$(GREEN)✓ Dependencies ready$(NC)"

dev: ## Run with hot reload (requires air)
	@which air > /dev/null || (echo "$(YELLOW)Installing air...$(NC)" && go install github.com/cosmtrek/air@latest)
	@air

docker-up: ## Start database in Docker
	@echo "$(GREEN)Starting PostgreSQL in Docker...$(NC)"
	@docker-compose up -d
	@echo "$(GREEN)✓ PostgreSQL running on port $(DB_PORT)$(NC)"

docker-down: ## Stop Docker containers
	@echo "$(YELLOW)Stopping Docker containers...$(NC)"
	@docker-compose down
	@echo "$(GREEN)✓ Containers stopped$(NC)"

.DEFAULT_GOAL := help