#!/bin/bash

BUILD_DIR="/tmp/jarvscript-build"
CURRENT_DIR=$(pwd)
FINAL_BINARY="/usr/bin/jarvscript"

echo "=== Autonomous build and installation of JarvScript v0.1.0 ==="

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

echo "🔒 Requesting sudo permissions to install the browser into your system..."
sudo cp "$APPIMAGE_PATH" "$FINAL_BINARY"
sudo chmod +x "$FINAL_BINARY"

echo "🔗 Setting up global system aliases..."
if [ -f "$HOME/.bashrc" ]; then
    echo "alias jarvscript='$FINAL_BINARY'" >> "$HOME/.bashrc"
fi
if [ -f "$HOME/.zshrc" ]; then
    echo "alias jarvscript='$FINAL_BINARY'" >> "$HOME/.zshrc"
fi

echo "🧹 Build completed. Removing temporary files, package.json, and node_modules..."
cd "$CURRENT_DIR" || exit
rm -rf "$BUILD_DIR"
rm -f package-lock.json

echo "=== 🎉 Success! JarvScript has been installed to $FINAL_BINARY ==="
echo "All build residue was purged. Restart your terminal and run: jarvscript"
