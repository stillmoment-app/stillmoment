.PHONY: help website website-setup screenshots-ios screenshots-android screenshots-all tickets-index tickets-check test-tickets

help: ## Show this help message
	@echo "Still Moment - Project Commands"
	@echo "================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Platform-specific commands:"
	@echo "  cd ios && make help"
	@echo "  cd android && ./gradlew tasks"

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
	@cd ios && make screenshots

screenshots-android: ## Generate Android screenshots (Paparazzi)
	@echo "🤖 Generating Android screenshots..."
	@cd android && ./gradlew screenshots

screenshots-all: screenshots-ios screenshots-android ## Generate all screenshots (iOS + Android)
	@echo ""
	@echo "✅ All screenshots generated!"
	@echo "   iOS:     docs/images/screenshots/"
	@echo "   Android: android/screenshots/"

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
