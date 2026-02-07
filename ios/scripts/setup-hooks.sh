#!/bin/bash
#
# Setup script for Git hooks and development tools
# Run this after cloning the repository
#

set -e

echo "🚀 Setting up Still Moment development environment..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install from https://brew.sh"
    exit 1
fi

echo "📦 Installing development tools..."

# Install SwiftLint
if ! command -v swiftlint &> /dev/null; then
    echo "  Installing SwiftLint..."
    brew install swiftlint
else
    echo "  ✅ SwiftLint already installed"
fi

# Install SwiftFormat
if ! command -v swiftformat &> /dev/null; then
    echo "  Installing SwiftFormat..."
    brew install swiftformat
else
    echo "  ✅ SwiftFormat already installed"
fi

# Install pre-commit
if ! command -v pre-commit &> /dev/null; then
    echo "  Installing pre-commit..."
    brew install pre-commit
else
    echo "  ✅ pre-commit already installed"
fi

# Install detect-secrets for secret scanning
if ! command -v detect-secrets &> /dev/null; then
    echo "  Installing detect-secrets..."
    brew install detect-secrets
else
    echo "  ✅ detect-secrets already installed"
fi

# Install xcbeautify for clean xcodebuild output
if ! command -v xcbeautify &> /dev/null; then
    echo "  Installing xcbeautify..."
    brew install xcbeautify
else
    echo "  ✅ xcbeautify already installed"
fi

echo ""
echo "🔧 Setting up Git hooks..."

# Initialize pre-commit hooks
pre-commit install

# Create secrets baseline if it doesn't exist
if [ ! -f .secrets.baseline ]; then
    echo "  Creating secrets baseline..."
    detect-secrets scan > .secrets.baseline
else
    echo "  ✅ Secrets baseline already exists"
fi

echo ""
echo "🎯 Running initial checks..."

# Run SwiftLint
echo "  Running SwiftLint..."
swiftlint lint || echo "  ⚠️  SwiftLint found issues (see above)"

# Run SwiftFormat check
echo "  Checking Swift formatting..."
swiftformat --lint . || echo "  ⚠️  SwiftFormat found issues (run 'swiftformat .' to fix)"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Run 'swiftformat .' to format all Swift files"
echo "  2. Fix any SwiftLint warnings"
echo "  3. Open StillMoment.xcodeproj in Xcode"
echo "  4. Build and run tests (⌘U)"
echo ""
echo "💡 Tips:"
echo "  - Pre-commit hooks will run automatically before each commit"
echo "  - Run 'swiftformat .' to format code"
echo "  - Run 'swiftlint' to check for issues"
echo "  - See DEVELOPMENT.md for more details"
echo ""
