#!/bin/bash
# CrossAgentCoding macOS distribution builder
# Run on macOS to create a .dmg installer
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$ROOT/build/macos"
DMG_DIR="$BUILD_DIR/dmg"
APP_NAME="CrossAgentCoding"
VERSION="0.0.1"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "=== Building CrossAgentCoding macOS distribution ==="

# Clean and prepare
rm -rf "$BUILD_DIR"
mkdir -p "$DMG_DIR"

# Copy macOS source files
echo "Copying macOS source files..."
cp "$ROOT/macos/cac.mjs" "$DMG_DIR/"
cp -r "$ROOT/macos/lib" "$DMG_DIR/"
cp -r "$ROOT/macos/web" "$DMG_DIR/"

# Copy shared files
cp "$ROOT/LICENSE" "$DMG_DIR/" 2>/dev/null || true
cp "$ROOT/README.md" "$DMG_DIR/"
cp "$ROOT/README.zh-CN.md" "$DMG_DIR/"
cp "$ROOT/README.zh-TW.md" "$DMG_DIR/"

# Copy Windows source (for reference / cross-platform use)
mkdir -p "$DMG_DIR/src"
cp "$ROOT/src/AgentMemoryManager.ps1" "$DMG_DIR/src/"
cp "$ROOT/src/launch.vbs" "$DMG_DIR/src/" 2>/dev/null || true
cp -r "$ROOT/scripts" "$DMG_DIR/"
cp -r "$ROOT/tests" "$DMG_DIR/"
cp "$ROOT/trae-mcp-config.json" "$DMG_DIR/" 2>/dev/null || true

# Create launcher script
cat > "$DMG_DIR/crossagentcoding" << 'LAUNCHER'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$SCRIPT_DIR/cac.mjs" "$@"
LAUNCHER
chmod +x "$DMG_DIR/crossagentcoding"

# Create a symlink-friendly wrapper for /usr/local/bin
cat > "$DMG_DIR/crossagentcoding.sh" << 'WRAPPER'
#!/bin/bash
# CrossAgentCoding macOS launcher
# Place this in /usr/local/bin or add to PATH
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
exec node "$INSTALL_DIR/cac.mjs" "$@"
WRAPPER
chmod +x "$DMG_DIR/crossagentcoding.sh"

# Create .dmg
echo "Creating DMG..."
DMG_PATH="$ROOT/release/$DMG_NAME"
mkdir -p "$ROOT/release"

# Remove old dmg if exists
rm -f "$DMG_PATH"

# Create DMG using hdiutil (macOS only)
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

echo "=== DMG created: $DMG_PATH ==="
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"

# Also create a zip for convenience
ZIP_PATH="$ROOT/release/${APP_NAME}-macOS-${VERSION}.zip"
echo "Creating ZIP..."
cd "$BUILD_DIR"
zip -r "$ZIP_PATH" dmg/
echo "=== ZIP created: $ZIP_PATH ==="
