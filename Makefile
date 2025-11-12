.PHONY: help format lint test test-unit test-ui test-single test-failures coverage test-report simulator-reset test-clean test-clean-unit setup screenshots

help: ## Show this help message
	@echo "Still Moment - Available Commands"
	@echo "==============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

format: ## Format code with SwiftFormat
	@echo "🎨 Formatting code..."
	@swiftformat .

lint: ## Lint code with SwiftLint (strict mode)
	@echo "🔍 Linting code..."
	@swiftlint lint --strict

test: ## Run all tests (unit + UI) with coverage report
	@./scripts/run-tests.sh

test-unit: ## Run unit tests only (faster, NO COVERAGE - use 'make test' for coverage)
	@./scripts/run-tests.sh --skip-ui-tests

test-ui: ## Run UI tests only (NO COVERAGE - use 'make test' for coverage)
	@./scripts/run-tests.sh --only-ui-tests

test-single: ## Run single test (usage: make test-single TEST=TestClass/testMethod)
	@./scripts/run-single-test.sh $(TEST)

test-failures: ## List all failing tests from last test run
	@./scripts/list-test-failures.sh

test-report: ## Display coverage report from last test run
	@./scripts/test-report.sh

simulator-reset: ## Reset iOS Simulator (reduces Spotlight/WidgetRenderer crashes)
	@echo "🔄 Resetting iOS Simulator..."
	@echo "   This helps reduce Spotlight/WidgetRenderer crashes during UI tests"
	@xcrun simctl shutdown all 2>/dev/null || true
	@xcrun simctl erase all 2>/dev/null || true
	@echo "   ✅ Simulator reset complete"

test-clean: ## Reset simulator and run all tests (unit + UI)
	@./scripts/run-tests.sh --reset-simulator

test-clean-unit: ## Reset simulator and run unit tests only
	@./scripts/run-tests.sh --reset-simulator --skip-ui-tests

setup: ## Setup development environment (one-time setup)
	@echo "🚀 Setting up development environment..."
	@./scripts/setup-hooks.sh

check: format lint ## Run format and lint checks
	@echo "✅ All checks passed!"

commit-check: format lint ## Pre-commit checks (format + lint)
	@echo "✅ Ready to commit!"

screenshots: ## INTERACTIVE: Generate all screenshots with guided prompts
	@./scripts/take-screenshots-interactive.sh
