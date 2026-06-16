#!/bin/bash
set -euo pipefail

# =============================================================================
# CrossAgnetCoding macOS DMG Build Script
# =============================================================================
# Output: release/CrossAgnetCoding-0.0.1.dmg
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
SRC_DIR="$ROOT/src"
RELEASE_DIR="$ROOT/release"
APP_NAME="CrossAgnetCoding"
VERSION="0.0.1"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"

# Temporary build dirs (cleaned after DMG is created)
BUILD_DIR="$RELEASE_DIR/_build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "============================================"
echo " CrossAgnetCoding macOS DMG Build"
echo "============================================"
echo ""

# --- Prerequisite checks ---
echo "[1/6] Checking prerequisites..."

if ! command -v pwsh &>/dev/null; then
    echo "  ⚠ WARNING: PowerShell (pwsh) is not installed (runtime dependency)."
    echo "    Users will need: brew install powershell"
else
    echo "  ✓ pwsh $(pwsh --version 2>/dev/null || echo '(found)')"
fi

if ! command -v node &>/dev/null; then
    echo "WARNING: Node.js not installed (needed at runtime)."
    echo "  Install: brew install node@20"
else
    echo "  ✓ node $(node --version)"
fi

# --- Clean ---
echo ""
echo "[2/6] Cleaning..."
rm -rf "$RELEASE_DIR" 2>/dev/null || true
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
echo "  ✓ Cleaned"

# --- Copy source ---
echo ""
echo "[3/6] Copying source files..."
cp "$SRC_DIR/AgentMemoryManager.ps1" "$MACOS_DIR/"
echo "  ✓ AgentMemoryManager.ps1"

# --- Create launcher ---
echo ""
echo "[4/6] Creating launcher..."

cat > "$MACOS_DIR/launcher.sh" << 'LAUNCHER_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PS1_PATH="$SCRIPT_DIR/AgentMemoryManager.ps1"
if [ $# -eq 0 ]; then
    exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$PS1_PATH" -Tui
else
    exec pwsh -NoProfile -ExecutionPolicy Bypass -File "$PS1_PATH" "$@"
fi
LAUNCHER_EOF
chmod +x "$MACOS_DIR/launcher.sh"
echo "  ✓ launcher.sh"

# --- Info.plist ---
cat > "$CONTENTS_DIR/Info.plist" << 'PLIST_EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>launcher.sh</string>
    <key>CFBundleIdentifier</key>
    <string>com.crossagnetcoding.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CrossAgnetCoding</string>
    <key>CFBundleDisplayName</key>
    <string>CrossAgnetCoding</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.0.1</string>
    <key>CFBundleVersion</key>
    <string>0.0.1</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
PLIST_EOF
echo "  ✓ Info.plist"

# --- Icon ---
echo ""
echo "[5/6] Generating icon..."

ICON_SRC="$ROOT/icon/_preview.png"

if command -v sips &>/dev/null && command -v iconutil &>/dev/null && [ -f "$ICON_SRC" ]; then
    ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    for SIZE in 16 32 128 256 512; do
        sips -z $SIZE $SIZE "$ICON_SRC" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" >/dev/null 2>&1
        DOUBLE=$((SIZE * 2))
        sips -z $DOUBLE $DOUBLE "$ICON_SRC" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" >/dev/null 2>&1
    done
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null
    rm -rf "$ICONSET_DIR"
    echo "  ✓ AppIcon.icns (from icon/_preview.png)"
elif [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$RESOURCES_DIR/AppIcon.png"
    echo "  ✓ AppIcon.png (from icon/_preview.png, no iconutil)"
else
    python3 -c "
import struct, zlib, os
def chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
w, h = 256, 256
raw = b''
for y in range(h):
    raw += b'\x00'
    for x in range(w):
        cx, cy = w//2, h//2
        dx, dy = x - cx, y - cy
        dist = (dx*dx + dy*dy) ** 0.5
        r = w * 0.42
        if dist < r:
            ratio = dist / r
            raw += bytes([int(120+80*(1-ratio)), int(60+100*(1-ratio)), int(180+50*(1-ratio))])
        elif dist < r + 8:
            raw += bytes([80, 30, 140])
        else:
            raw += bytes([40, 40, 45])
png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
os.makedirs('$RESOURCES_DIR', exist_ok=True)
with open('$RESOURCES_DIR/AppIcon.png', 'wb') as f:
    f.write(png)
print('  ✓ AppIcon.png (placeholder)')
" 2>/dev/null || echo "  ⚠ Icon skipped (no python3)"
fi

# --- Create DMG ---
echo ""
echo "[6/6] Creating DMG..."

DMG_STAGING="$BUILD_DIR/_staging"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -sfn /Applications "$DMG_STAGING/Applications" 2>/dev/null || true

if command -v hdiutil &>/dev/null; then
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$DMG_STAGING" \
        -ov -format UDZO \
        -fs HFS+ \
        "$DMG_PATH" >/dev/null 2>&1
    echo "  ✓ DMG created (hdiutil)"
else
    # Fallback: pure-Python UDZO DMG creator (cross-platform)
    python3 "$SCRIPT_DIR/mkdmgtool.py" "$DMG_STAGING" "$DMG_PATH" "$APP_NAME"
    echo "  ✓ DMG created (mkdmgtool)"
fi

# --- Clean up temp build dir, keep only the .dmg ---
rm -rf "$BUILD_DIR"

echo ""
echo "============================================"
echo " Build Complete!"
echo "============================================"
echo ""
echo "  💿 $DMG_PATH  ($(du -sh "$DMG_PATH" | awk '{print $1}'))"
echo ""
echo "Usage:"
echo "  open \"$DMG_PATH\"           # 挂载 DMG，拖入 Applications"
echo "  hdiutil attach \"$DMG_PATH\"  # 命令行挂载"
echo ""
