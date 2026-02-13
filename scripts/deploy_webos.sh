#!/bin/bash

# Configuration
TV_IP="192.168.68.58"
TV_PORT="9922"
TV_USER="prisoner"
TV_PASS="629001"

echo "📺 Deploying to WebOS TV at $TV_IP..."

# Check connectivity
echo "Checking connection to TV..."
if ! nc -z -w 2 $TV_IP $TV_PORT; then
    echo "❌ TV not reachable on port $TV_PORT. Please enable Developer Mode and Key Server on the TV."
    exit 1
fi

# Build web app if needed
if [ ! -d "build/web" ]; then
    echo "🏗️  Building Flutter Web app..."
    flutter build web --release --no-tree-shake-icons
else
    echo "✅ Web build exists. Skipping build."
fi

# Package
echo "📦 Packaging IPK..."
mkdir -p webos
cp -R build/web/* webos/
# Ensure icon exists
if [ ! -f "webos/icon.png" ]; then
    touch webos/icon.png
fi
if [ ! -f "webos/largeIcon.png" ]; then
    touch webos/largeIcon.png
fi

npm install --silent
node_modules/.bin/ares-package webos --no-minify

# Setup device
echo "🔌 Configuring device..."
node_modules/.bin/ares-setup-device -a tv -i "host=$TV_IP" -i "port=$TV_PORT" -i "username=$TV_USER" -i "password=$TV_PASS" --default || \
node_modules/.bin/ares-setup-device -m tv -i "host=$TV_IP" -i "port=$TV_PORT" -i "username=$TV_USER" -i "password=$TV_PASS" --default

# Install
echo "🚀 Installing IPK..."
IPK_FILE=$(ls *.ipk | head -n 1)
node_modules/.bin/ares-install "$IPK_FILE" -d tv

echo "✅ Deployment complete!"
