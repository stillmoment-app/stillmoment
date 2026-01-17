.PHONY: help format check test build clean screenshot-setup screenshots release release-dry release-production metadata release-prepare

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

test: ## Run unit tests
	@echo "Running unit tests..."
	@./gradlew test

build: ## Build debug APK
	@echo "Building debug APK..."
	@./gradlew assembleDebug

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

release: ## Upload to Play Store Closed Testing
	@echo "Building and uploading to Closed Testing..."
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

release-production: ## Upload to Production (with confirmation)
	@echo "Preparing production release..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane release_production

metadata: ## Update only metadata (descriptions, changelogs) without new build
	@echo "Updating Play Store metadata..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane metadata

screenshots-upload: ## Upload screenshots to Play Store without new build
	@echo "Uploading screenshots to Play Store..."
	@if [ ! -d "vendor/bundle" ]; then \
		echo "Run 'make screenshot-setup' first to install dependencies"; \
		exit 1; \
	fi
	@bundle exec fastlane screenshots_upload

release-prepare: ## Prepare release (VERSION=x.y.z required, DRY_RUN=1 optional)
	@./scripts/release-prepare.sh $(VERSION) $(DRY_RUN)
