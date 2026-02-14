#!/bin/bash
# Quick deploy script for iPhone TonyB-33
# Usage: ./scripts/deploy_iphone.sh

set -e

DEVICE_ID="00008120-00060C642170201E"
BUNDLE_ID="com.example.xupertbApp"
FLUTTER_SDK="/Users/luisblancofontela/.gemini/antigravity/scratch/flutter_sdk"

export PATH="$FLUTTER_SDK/bin:$PATH"

echo "🧹 Cleaning up processes..."
pkill -9 -f "flutter.*logs.*$DEVICE_ID" 2>/dev/null || true
pkill -9 -f "iproxy.*$DEVICE_ID" 2>/dev/null || true
pkill -9 -f "iPhone Mirroring" 2>/dev/null || true
osascript -e 'quit app "iPhone Mirroring"' 2>/dev/null || true
sleep 2

echo "🔨 Building iOS debug..."
flutter build ios --debug

echo "📦 Installing on iPhone..."
# Only uninstall if there's a version mismatch (keeps trust)
xcrun devicectl device install app --device $DEVICE_ID build/ios/iphoneos/Runner.app 2>&1 | tee /tmp/install.log
if grep -q "error" /tmp/install.log; then
  echo "⚠️  Install failed, removing old version and retrying..."
  xcrun devicectl device uninstall app --device $DEVICE_ID $BUNDLE_ID 2>/dev/null || true
  xcrun devicectl device install app --device $DEVICE_ID build/ios/iphoneos/Runner.app
fi

echo "🚀 Launching app..."
xcrun devicectl device process launch --device $DEVICE_ID $BUNDLE_ID

echo "✅ Done! App should be running on iPhone."
echo "⚠️  If you see 'Security' error, trust the profile in Settings > General > VPN & Device Management"
