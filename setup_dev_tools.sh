#!/bin/bash
# NexTV App - Professional Development Setup Script
# Run this script to setup all development tools

set -e  # Exit on error

echo "🚀 NexTV App - Professional Development Setup"
echo "=============================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  This script is designed for macOS. Please install tools manually."
    exit 1
fi

echo "📋 Checking prerequisites..."
echo ""

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew not found${NC}"
    echo "   Install from: https://brew.sh"
    exit 1
else
    echo -e "${GREEN}✅ Homebrew installed${NC}"
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    # Try with custom path
    if [ -f "/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk/bin/flutter" ]; then
        export PATH="/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk/bin:$PATH"
        echo -e "${GREEN}✅ Flutter found (custom path)${NC}"
    else
        echo -e "${RED}❌ Flutter not found${NC}"
        echo "   Install from: https://flutter.dev"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Flutter installed${NC}"
fi

echo ""
echo "📦 Installing development tools..."
echo ""

# Install Lefthook
if ! command -v lefthook &> /dev/null; then
    echo "Installing Lefthook..."
    brew install lefthook
    echo -e "${GREEN}✅ Lefthook installed${NC}"
else
    echo -e "${GREEN}✅ Lefthook already installed${NC}"
fi

# Install TruffleHog
if ! command -v trufflehog &> /dev/null; then
    echo "Installing TruffleHog..."
    brew install trufflesecurity/trufflehog/trufflehog
    echo -e "${GREEN}✅ TruffleHog installed${NC}"
else
    echo -e "${GREEN}✅ TruffleHog already installed${NC}"
fi

# Install LCOV
if ! command -v lcov &> /dev/null; then
    echo "Installing LCOV..."
    brew install lcov
    echo -e "${GREEN}✅ LCOV installed${NC}"
else
    echo -e "${GREEN}✅ LCOV already installed${NC}"
fi

echo ""
echo "🔧 Setting up project..."
echo ""

# Navigate to project directory
PROJECT_DIR="/Users/luisblancofontela/Development/nextv_app"
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Project directory not found: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR"

# Install Flutter dependencies
echo "Installing Flutter dependencies..."
flutter pub get
echo -e "${GREEN}✅ Flutter dependencies installed${NC}"

# Setup Lefthook
echo "Setting up Git hooks..."
lefthook install
echo -e "${GREEN}✅ Git hooks installed${NC}"

echo ""
echo "🧪 Running validation checks..."
echo ""

# Run Flutter analyze
echo "Running Flutter analyze..."
if flutter analyze --fatal-infos; then
    echo -e "${GREEN}✅ Code analysis passed${NC}"
else
    echo -e "${YELLOW}⚠️  Code analysis found issues (non-blocking)${NC}"
fi

# Run tests
echo "Running tests..."
if flutter test; then
    echo -e "${GREEN}✅ Tests passed${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed (non-blocking)${NC}"
fi

# Run TruffleHog
echo "Running security scan..."
if trufflehog filesystem . --no-update 2>&1 | grep -q "No secrets found"; then
    echo -e "${GREEN}✅ No secrets found${NC}"
else
    echo -e "${YELLOW}⚠️  Security scan found potential issues${NC}"
fi

echo ""
echo "📊 Generating reports..."
echo ""

# Generate test coverage
echo "Generating test coverage..."
flutter test --coverage
if [ -f "coverage/lcov.info" ]; then
    # Generate HTML report
    genhtml coverage/lcov.info -o coverage/html 2>/dev/null || true
    echo -e "${GREEN}✅ Coverage report generated${NC}"
    echo "   View at: coverage/html/index.html"
else
    echo -e "${YELLOW}⚠️  Coverage report not generated${NC}"
fi

echo ""
echo "=============================================="
echo "🎉 Setup Complete!"
echo "=============================================="
echo ""
echo "✅ All development tools installed and configured!"
echo ""
echo "📚 Next Steps:"
echo ""
echo "1. Read the implementation guide:"
echo "   open docs/IMPLEMENTATION_GUIDE.md"
echo ""
echo "2. Review the upgrade summary:"
echo "   open UPGRADE_SUMMARY.md"
echo ""
echo "3. Start with Sprint 1 (Security):"
echo "   open docs/REFACTORING_PLAN.md"
echo ""
echo "4. Test the Git hooks:"
echo "   git add ."
echo "   git commit -m 'test: git hooks validation'"
echo ""
echo "5. View CI/CD workflows:"
echo "   cat .github/workflows/ci.yml"
echo ""
echo "🔧 Useful commands:"
echo ""
echo "   flutter analyze        # Static analysis"
echo "   flutter test           # Run tests"
echo "   dart format .          # Format code"
echo "   lefthook run pre-commit # Test hooks"
echo "   trufflehog filesystem . --no-update # Security scan"
echo ""
echo "📖 Documentation:"
echo "   docs/IMPLEMENTATION_GUIDE.md    - Complete guide"
echo "   docs/BEST_PRACTICES.md          - Coding standards"
echo "   docs/SECURITY_IMPLEMENTATION.md - Security guide"
echo "   docs/REFACTORING_PLAN.md        - 4-week roadmap"
echo ""
echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""
