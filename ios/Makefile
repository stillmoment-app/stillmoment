.PHONY: help format lint check-localization validate-localization test test-unit test-ui test-single test-failures test-report simulator-reset test-clean setup check screenshots screenshot-setup

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

check-localization: ## Check for hardcoded UI strings in code (should be localized)
	@./scripts/check-localization.sh

validate-localization: ## Validate localization files for completeness and consistency
	@./scripts/validate-localization.sh

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

setup: ## Setup development environment (one-time setup)
	@echo "🚀 Setting up development environment..."
	@./scripts/setup-hooks.sh

check: format lint check-localization validate-localization ## Run format, lint, and localization checks
	@echo "✅ All checks passed!"

screenshot-setup: ## Setup Ruby/Fastlane environment (one-time)
	@echo "💎 Setting up Ruby/Fastlane environment..."
	@if ! command -v rbenv &> /dev/null; then \
		echo "❌ rbenv not found. Install with: brew install rbenv"; \
		exit 1; \
	fi
	@if ! rbenv versions | grep -q "$$(cat .ruby-version)"; then \
		echo "📦 Installing Ruby $$(cat .ruby-version)..."; \
		rbenv install $$(cat .ruby-version); \
	fi
	@echo "📦 Installing gems..."
	@bundle install --path vendor/bundle
	@echo "✅ Screenshot setup complete!"

screenshots: ## Generate all screenshots automatically (Fastlane)
	@echo "📸 Generating screenshots with Fastlane..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "❌ Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane screenshots
	@echo "✅ Screenshots generated in docs/images/screenshots/"
