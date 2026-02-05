.PHONY: help format format-check lint check-localization validate-localization test test-unit test-ui test-single test-failures test-report simulator-reset test-clean setup check analyze screenshots screenshot-setup screenshot-single release-prepare release release-dry metadata-download testflight

DEVICE ?= iPhone 17
IOS_VERSION ?= latest
ANALYZE_LOG ?= build/analyze.log

help: ## Show this help message
	@echo "Still Moment - Available Commands"
	@echo "==============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

format: ## Format code with SwiftFormat
	@echo "🎨 Formatting code..."
	@swiftformat .

format-check: ## Check formatting without modifying files
	@echo "🔍 Checking code formatting..."
	@swiftformat --lint .

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

ifdef CI
check: format-check lint check-localization validate-localization ## Run all static code checks (format, lint, localization)
else
check: format lint check-localization validate-localization
endif
	@echo "✅ All checks passed!"

analyze: ## Run Xcode static analysis (fails on any warning)
	@echo "🔬 Running Xcode static analysis..."
	@mkdir -p $(dir $(ANALYZE_LOG))
	@xcodebuild analyze \
		-project StillMoment.xcodeproj \
		-scheme StillMoment \
		-destination "platform=iOS Simulator,name=$(DEVICE),OS=$(IOS_VERSION)" \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		CODE_SIGNING_ALLOWED=NO \
		2>&1 | tee $(ANALYZE_LOG)
	@if grep -qE ':[0-9]+:[0-9]+: warning:' $(ANALYZE_LOG); then \
		echo "❌ Static analysis found warnings:"; \
		grep -E ':[0-9]+:[0-9]+: warning:' $(ANALYZE_LOG); \
		exit 1; \
	else \
		echo "✅ No static analysis warnings found"; \
	fi

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

screenshot-single: ## Run single screenshot test in EN + DE (TEST=testScreenshot05_SettingsView)
	@if [ -z "$(TEST)" ]; then \
		echo "Usage: make screenshot-single TEST=testScreenshot05_SettingsView"; \
		exit 1; \
	fi
	@if [ ! -d "vendor/bundle" ]; then \
		echo "❌ Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@echo "📸 Running screenshot: $(TEST) (EN + DE via Fastlane)..."
	@bundle exec fastlane screenshot_single test:$(TEST)
	@echo "✅ Screenshots → docs/images/screenshots/"

release-prepare: ## Prepare release (VERSION=x.y.z required, DRY_RUN=1 optional, SKIP_SCREENSHOTS=1 optional)
	@VERSION=$(VERSION) DRY_RUN=$(DRY_RUN) SKIP_SCREENSHOTS=$(SKIP_SCREENSHOTS) ./scripts/release-prepare.sh

release: ## Build and upload to App Store Connect (VERSION=x.y.z required, SKIP_BUILD=1 optional)
	@if [ -z "$(VERSION)" ]; then \
		echo "Usage: make release VERSION=x.y.z [SKIP_BUILD=1]"; \
		exit 1; \
	fi
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@if [ -n "$(SKIP_BUILD)" ]; then \
		echo "Uploading metadata for version $(VERSION) to App Store Connect..."; \
		bundle exec fastlane release version:$(VERSION) build:false; \
	else \
		echo "Building and uploading version $(VERSION) to App Store Connect..."; \
		bundle exec fastlane release version:$(VERSION) build:true; \
	fi

release-dry: ## Validate App Store Connect configuration (no upload)
	@echo "Validating App Store Connect configuration..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane release_dry

metadata-download: ## Download metadata from App Store Connect
	@echo "Downloading metadata from App Store Connect..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane download_metadata

testflight: ## Upload build to TestFlight
	@echo "Building and uploading to TestFlight..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane testflight_upload
