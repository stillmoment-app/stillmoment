.PHONY: help sync format lint test coverage setup

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

test: ## Run all tests in Xcode (requires Xcode to be open)
	@echo "🧪 Run tests with ⌘U in Xcode"
	@echo "   Or use: xcodebuild test -project MediTimer.xcodeproj -scheme MediTimer -destination 'platform=iOS Simulator,name=iPhone 15 Pro'"

coverage: ## Generate code coverage report
	@echo "📊 Generating coverage report..."
	@./scripts/generate-coverage-report.sh

setup: ## Setup development environment (one-time setup)
	@echo "🚀 Setting up development environment..."
	@./scripts/setup-hooks.sh

check: format lint ## Run format and lint checks
	@echo "✅ All checks passed!"

commit-check: format lint ## Pre-commit checks (format + lint)
	@echo "✅ Ready to commit!"
