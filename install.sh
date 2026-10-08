#!/bin/bash

BUILD_DIR="/tmp/jarvscript-build"
CURRENT_DIR=$(pwd)
OUTPUT_BINARY="jarvscript-0.1.1.AppImage"

echo "=== Autonomous compilation of JarvScript v0.1.1 ==="

if [ ! -f "./main.js" ] || [ ! -d "./browser" ]; then
    echo "❌ Error: Script must be executed from the directory containing main.js and browser/!"
    exit 1
fi

echo "📦 Creating temporary build environment in $BUILD_DIR..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/browser"

cp "./main.js" "$BUILD_DIR/"
cp -r "./browser/"* "$BUILD_DIR/browser/"

cd "$BUILD_DIR" || exit 1

echo "📝 Generating configuration files..."
cat << 'EOF' > package.json
{
  "name": "jarvscript",
  "version": "0.1.1",
  "description": "JarvScript Advanced Core Browser",
  "author": "jarvbro",
  "main": "main.js",
  "scripts": {
    "build": "npx electron-builder --linux"
  },
  "build": {
    "appId": "com.jarvscript.browser",
    "asar": true,
    "linux": {
      "target": ["AppImage"],
      "category": "Network"
    },
    "files": [
      "main.js",
      "browser/**/*"
    ]
  }
}
EOF

echo "📥 Downloading and extracting node_modules into temporary folder..."
npm install electron --save-dev --no-audit --no-fund
npm install electron-builder --save-dev --no-audit --no-fund
npm install better-sqlite3 --no-audit --no-fund

echo "⚙️ Compiling monolithic AppImage..."
npm run build

APPIMAGE_PATH=$(ls dist/jarvscript-0.1.1.AppImage 2>/dev/null)

if [ -z "$APPIMAGE_PATH" ]; then
    echo "❌ Error: Compilation failed. Check the logs above."
    rm -rf "$BUILD_DIR"
    exit 1
fi

cp "$APPIMAGE_PATH" "$CURRENT_DIR/$OUTPUT_BINARY"
chmod +x "$CURRENT_DIR/$OUTPUT_BINARY"

echo "🧹 Build completed. Purging temporary files..."
cd "$CURRENT_DIR" || exit
rm -rf "$BUILD_DIR"
rm -f package-lock.json

echo "=== 🎉 Success! Monolithic binary created: ./$OUTPUT_BINARY ==="
