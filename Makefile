.PHONY: help sync format lint test test-unit test-single test-failures coverage test-report setup

help: ## Show this help message
	@echo "MediTimer - Available Commands"
	@echo "==============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

sync: ## Sync new Swift files with Xcode project
	@echo "🔄 Syncing files with Xcode..."
	@./scripts/sync-xcode-files.sh

format: ## Format code with SwiftFormat
	@echo "🎨 Formatting code..."
	@swiftformat .

lint: ## Lint code with SwiftLint (strict mode)
	@echo "🔍 Linting code..."
	@swiftlint lint --strict

test: ## Run all tests (unit + UI) with coverage report
	@./scripts/run-tests.sh

test-unit: ## Run unit tests only (faster, skip UI tests)
	@./scripts/run-tests.sh --skip-ui-tests

test-single: ## Run single test (usage: make test-single TEST=TestClass/testMethod)
	@./scripts/run-single-test.sh $(TEST)

test-failures: ## List all failing tests from last test run
	@./scripts/list-test-failures.sh

coverage: ## Run all tests with coverage report (alias for 'make test')
	@./scripts/run-tests.sh

test-report: ## Display coverage report from last test run
	@./scripts/test-report.sh

setup: ## Setup development environment (one-time setup)
	@echo "🚀 Setting up development environment..."
	@./scripts/setup-hooks.sh

check: format lint ## Run format and lint checks
	@echo "✅ All checks passed!"

commit-check: format lint ## Pre-commit checks (format + lint)
	@echo "✅ Ready to commit!"
