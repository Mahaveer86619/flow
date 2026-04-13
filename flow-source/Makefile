.PHONY: build run down clean logs

build:
	@echo "Building..."
	@docker compose up --build

run:
	@echo "Running..."
	@docker compose up -d

down:
	@echo "Stopping..."
	@docker compose down

clean:
	@echo "Cleaning..."
	@docker compose down -v

logs:
	@echo "Showing logs..."
	@docker compose logs -f
