.PHONY: setup get analyze clean test build-apk build-ios build-macos doctor

FLUTTER_ROOT = /Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk
FLUTTER = $(FLUTTER_ROOT)/bin/flutter

# Setup environment (run once per terminal session)
setup:
	@echo "Run this command instead:"
	@echo "source scripts/setup_mac.sh"

# Get dependencies
get:
	$(FLUTTER) pub get

# Analyze code
analyze:
	$(FLUTTER) analyze

# Clean build artifacts
clean:
	$(FLUTTER) clean

# Run tests
test:
	$(FLUTTER) test

# Build Android APK
build-apk:
	$(FLUTTER) build apk --release

# Build iOS (requires Xcode)
build-ios:
	$(FLUTTER) build ios --release

# Build macOS (requires Xcode)
build-macos:
	$(FLUTTER) build macos --release

# Check Flutter setup
doctor:
	$(FLUTTER) doctor -v

# Help
help:
	@echo "NeXtv Build Commands:"
	@echo "  make get         - Install dependencies"
	@echo "  make analyze     - Analyze code"
	@echo "  make test        - Run tests"
	@echo "  make clean       - Clean build artifacts"
	@echo "  make build-apk   - Build Android APK"
	@echo "  make build-ios   - Build iOS app"
	@echo "  make build-macos - Build macOS app"
	@echo "  make doctor      - Check Flutter setup"
	@echo ""
	@echo "First time setup:"
	@echo "  source scripts/setup_mac.sh"
