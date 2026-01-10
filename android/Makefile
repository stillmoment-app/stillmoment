.PHONY: help format check test build clean

help: ## Show this help message
	@echo "Still Moment Android - Available Commands"
	@echo "========================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

format: ## Format code with ktlint
	@echo "Formatting code..."
	@./gradlew ktlintFormat

check: ## Run all code quality checks (ktlint, lint, detekt) - same as CI
	@echo "Running code quality checks..."
	@./gradlew ktlintCheck lint detekt
	@echo "All checks passed!"

test: ## Run unit tests
	@echo "Running unit tests..."
	@./gradlew test

build: ## Build debug APK
	@echo "Building debug APK..."
	@./gradlew assembleDebug

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@./gradlew clean
