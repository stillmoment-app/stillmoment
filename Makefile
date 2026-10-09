.PHONY: help website website-setup screenshots-ios screenshots-android screenshots-all release-prepare release tickets-index tickets-check test-tickets test-release-tooling

help: ## Show this help message
	@echo "Still Moment - Project Commands"
	@echo "================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Platform-specific commands:"
	@echo "  make -C ios help"
	@echo "  make -C android help"

website-setup: ## Setup Ruby/Jekyll environment for website (one-time)
	@echo "💎 Setting up Ruby/Jekyll environment..."
	@if ! command -v rbenv &> /dev/null; then \
		echo "❌ rbenv not found. Install with: brew install rbenv"; \
		exit 1; \
	fi
	@if ! rbenv versions | grep -q "$$(cat docs/.ruby-version)"; then \
		echo "📦 Installing Ruby $$(cat docs/.ruby-version)..."; \
		rbenv install $$(cat docs/.ruby-version); \
	fi
	@echo "📦 Installing gems..."
	@cd docs && bundle install --path vendor/bundle
	@echo "✅ Website setup complete!"

website: ## Serve website locally (Jekyll)
	@echo "🌐 Starting local website server..."
	@if [ ! -d "docs/vendor/bundle" ]; then \
		echo "❌ Run 'make website-setup' first to install dependencies"; \
		exit 1; \
	fi
	@cd docs && bundle exec jekyll serve --open-url

# =============================================================================
# Screenshots
# =============================================================================

screenshots-ios: ## Generate iOS screenshots (Fastlane Snapshot)
	@echo "📱 Generating iOS screenshots..."
	@$(MAKE) -C ios screenshots

screenshots-android: ## Generate Android screenshots (Fastlane Screengrab)
	@echo "🤖 Generating Android screenshots..."
	@$(MAKE) -C android screenshots

screenshots-all: screenshots-ios screenshots-android ## Generate all screenshots (iOS + Android)
	@echo ""
	@echo "✅ All screenshots generated!"
	@echo "   iOS:     docs/images/screenshots/ + ios/fastlane/screenshots/"
	@echo "   Android: android/fastlane/metadata/android/*/images/phoneScreenshots/"

# =============================================================================
# Release (dev-docs/release/RELEASE_GUIDE.md)
# =============================================================================

release-prepare: ## Prepare iOS + Android release (VERSION=x.y.z, DRY_RUN=1, SKIP_SCREENSHOTS=1 optional)
	@$(MAKE) -C ios release-prepare VERSION=$(VERSION) DRY_RUN=$(DRY_RUN) SKIP_SCREENSHOTS=$(SKIP_SCREENSHOTS)
	@$(MAKE) -C android release-prepare VERSION=$(VERSION) DRY_RUN=$(DRY_RUN) SKIP_SCREENSHOTS=$(SKIP_SCREENSHOTS)

release: ## Upload iOS + Android to the stores (VERSION=x.y.z; both guards run before any upload)
	@VERSION=$(VERSION) ./scripts/release/release-guard.sh ios
	@VERSION=$(VERSION) ./scripts/release/release-guard.sh android
	@$(MAKE) -C ios release VERSION=$(VERSION)
	@$(MAKE) -C android release VERSION=$(VERSION)

# =============================================================================
# Tickets (dev-docs/tickets/)
# =============================================================================

tickets-index: ## Validate tickets and regenerate dev-docs/tickets/INDEX.md
	@uv run --quiet scripts/tickets/index.py

tickets-check: ## Validate tickets, fail if INDEX.md is outdated (no write)
	@uv run --quiet scripts/tickets/index.py --check

test-tickets: ## Run tests for the ticket tooling (pytest)
	@PYTHONDONTWRITEBYTECODE=1 uv run --quiet --no-project --with pytest --with pyyaml \
		pytest -p no:cacheprovider -q scripts/tickets/tests

# =============================================================================
# Release tooling (scripts/release/)
# =============================================================================

test-release-tooling: ## Run tests for the release preflight tooling (pytest)
	@PYTHONDONTWRITEBYTECODE=1 uv run --quiet --no-project --with pytest \
		pytest -p no:cacheprovider -q scripts/release/tests
