.PHONY: help build-release format check test test-unit test-unit-agent test-single test-single-agent test-ui test-ui-agent test-failures build clean screenshot-setup screenshots release release-dry release-production metadata release-prepare

# Android SDK paths (auto-detect if ANDROID_HOME not set)
ANDROID_HOME ?= $(HOME)/Library/Android/sdk
ADB := $(ANDROID_HOME)/platform-tools/adb
EMULATOR := $(ANDROID_HOME)/emulator/emulator

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

test: ## Run all unit tests (debug variant; release-only breakage: make build-release)
	@echo "Running all tests..."
	@./gradlew test

test-unit: ## Run unit tests with summary
	@./scripts/run-tests.sh

test-unit-agent: ## Run unit tests with agent-optimized output
	@./scripts/run-tests-agent.sh

test-single: ## Run single test (usage: make test-single TEST=ClassName or ClassName/method)
	@./scripts/run-tests.sh --single $(TEST)

test-single-agent: ## Run single test with agent output (usage: make test-single-agent TEST=ClassName or ClassName/method)
	@./scripts/run-tests-agent.sh --single $(TEST)

test-ui: ## Run all UI tests (androidTest) on the running emulator/device - same as CI check "Android UI Tests"
	@./gradlew connectedDebugAndroidTest

test-ui-agent: ## Run all UI tests with agent-optimized output (needs a running emulator/device)
	@./scripts/run-tests-agent.sh --ui

test-failures: ## List failing tests from last run
	@./scripts/list-test-failures.sh

build: ## Build debug APK
	@echo "Building debug APK..."
	@./gradlew assembleDebug

build-release: ## Build release bundle (minified; catches release-only breakage before tagging; debug-signed without keystore.properties)
	@echo "Building release bundle..."
	@./gradlew bundleRelease
	@echo "Release build succeeded: app/build/outputs/bundle/release/app-release.aab"

clean: ## Clean build artifacts
	@echo "Cleaning..."
	@./gradlew clean

screenshot-setup: ## Setup Ruby/Fastlane environment (one-time)
	@echo "Setting up Ruby/Fastlane environment..."
	@if ! command -v rbenv &> /dev/null; then \
		echo "rbenv not found. Install with: brew install rbenv"; \
		exit 1; \
	fi
	@if ! rbenv versions | grep -q "$$(cat .ruby-version)"; then \
		echo "Installing Ruby $$(cat .ruby-version)..."; \
		rbenv install $$(cat .ruby-version); \
	fi
	@echo "Installing gems..."
	@bundle install --path vendor/bundle
	@echo "Screenshot setup complete!"

screenshots: ## Generate all screenshots automatically (Fastlane Screengrab)
	@echo "Generating screenshots with Fastlane Screengrab..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@# Start emulator if not running
	@if ! "$(ADB)" devices | grep -q "emulator"; then \
		echo "Starting emulator..."; \
		AVD_NAME=$$("$(EMULATOR)" -list-avds | grep -i pixel | head -1); \
		if [ -z "$$AVD_NAME" ]; then \
			echo "No Pixel AVD found. Create one with:"; \
			echo "  avdmanager create avd -n Pixel_6_Pro_API_34 -k 'system-images;android-34;google_apis;arm64-v8a' -d 'pixel_6_pro'"; \
			exit 1; \
		fi; \
		echo "Using AVD: $$AVD_NAME"; \
		"$(EMULATOR)" -avd "$$AVD_NAME" -no-snapshot-load &>/dev/null & \
		echo "Waiting for emulator to boot..."; \
		"$(ADB)" wait-for-device; \
		while [ "$$("$(ADB)" shell getprop sys.boot_completed 2>/dev/null)" != "1" ]; do \
			sleep 2; \
		done; \
		echo "Emulator ready."; \
	else \
		echo "Emulator already running."; \
	fi
	@bundle exec fastlane screenshots
	@echo "Screenshots generated in fastlane/metadata/android/*/images/phoneScreenshots/"

release: ## Upload to Play Store (Production) (VERSION=x.y.z required; checks tag/version/screenshots first)
	@VERSION=$(VERSION) ../scripts/release/release-guard.sh android
	@echo "Building and uploading version $(VERSION) to Play Store (Production)..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane release

release-dry: ## Validate release without uploading (dry run)
	@echo "Validating release configuration..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane release_dry

release-production: ## Upload to Production with confirmation prompt (VERSION=x.y.z required; same checks as release)
	@VERSION=$(VERSION) ../scripts/release/release-guard.sh android
	@echo "Preparing production release of version $(VERSION)..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane release_production

metadata: ## Update only metadata (descriptions, changelogs) without new build (VERSION_CODE=n optional, default: versionCode in build.gradle.kts)
	@echo "Updating Play Store metadata..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane metadata $(if $(VERSION_CODE),version_code:$(VERSION_CODE))

screenshots-upload: ## Upload screenshots to Play Store without new build
	@echo "Uploading screenshots to Play Store..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane screenshots_upload

release-prepare: ## Prepare release (VERSION=x.y.z required, DRY_RUN=1 optional, SKIP_SCREENSHOTS=1 optional)
	@VERSION=$(VERSION) DRY_RUN=$(DRY_RUN) SKIP_SCREENSHOTS=$(SKIP_SCREENSHOTS) ./scripts/release-prepare.sh
