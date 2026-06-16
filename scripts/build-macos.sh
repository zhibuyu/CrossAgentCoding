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
# The macOS app is a pure Node.js implementation (no PowerShell). Node is only a
# RUNTIME dependency for the end user; it is not needed to build the bundle.
echo "[1/6] Checking prerequisites..."

if ! command -v node &>/dev/null; then
    echo "  ⚠ Node.js not found on this build machine (only needed at runtime)."
    echo "    End users will be prompted to install it on first launch."
else
    echo "  ✓ node $(node --version) (runtime dependency)"
fi

# --- Clean ---
echo ""
echo "[2/6] Cleaning..."
rm -rf "$RELEASE_DIR" 2>/dev/null || true
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
echo "  ✓ Cleaned"

# --- Copy source ---
echo ""
echo "[3/6] Copying Node.js source..."
APP_SRC_DIR="$RESOURCES_DIR/app"
mkdir -p "$APP_SRC_DIR"
cp "$ROOT/macos/cac.mjs" "$APP_SRC_DIR/"
cp -R "$ROOT/macos/lib" "$APP_SRC_DIR/"
cp -R "$ROOT/macos/web" "$APP_SRC_DIR/"
echo "  ✓ cac.mjs + lib/ + web/"

# --- Create launcher ---
echo ""
echo "[4/6] Creating launcher..."

# CFBundleExecutable: runs (without a TTY) when the .app is double-clicked.
# Finder launches with a minimal PATH, so we augment it the same way the Node
# child will and source nvm. If Node is present we launch the GUI headlessly
# (the manager itself opens a browser window — no Terminal clutter). If Node is
# missing we hand off to setup-node.command inside Terminal, which can show the
# install progress and guidance.
cat > "$MACOS_DIR/launcher.sh" << 'LAUNCHER_EOF'
#!/bin/bash
HERE="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$(cd "$HERE/../Resources/app" && pwd)"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1

if command -v node >/dev/null 2>&1; then
    # Run Node as a child (NOT exec): keeping this in-bundle script as the app's
    # process preserves the LaunchServices/Dock association, and the trap means a
    # Quit (SIGTERM) or window-close also tears down the Node server.
    node "$APP_DIR/cac.mjs" gui &
    NODE_PID=$!
    trap 'kill "$NODE_PID" 2>/dev/null' TERM INT EXIT
    wait "$NODE_PID"
else
    open -a Terminal "$APP_DIR/setup-node.command"
fi
LAUNCHER_EOF
chmod +x "$MACOS_DIR/launcher.sh"
echo "  ✓ launcher.sh"

# Runs inside Terminal.app only when Node is missing. Terminal sources the
# user's login profile, so most Node installs (Homebrew / official pkg / nvm)
# are already on PATH; we additionally prepend common bin dirs and source nvm.
# Offers a Homebrew install, otherwise opens nodejs.org and asks the user to
# reopen the app. Once Node is available it launches the GUI.
cat > "$APP_SRC_DIR/setup-node.command" << 'SETUP_EOF'
#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"
[ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh" >/dev/null 2>&1
APP_DIR="$(cd "$(dirname "$0")" && pwd)"

launch_gui() {
    clear
    exec node "$APP_DIR/cac.mjs" gui
}

command -v node >/dev/null 2>&1 && launch_gui

if command -v brew >/dev/null 2>&1; then
    CHOICE="$(osascript -e 'button returned of (display dialog "CrossAgnetCoding 需要 Node.js 运行。检测到 Homebrew，是否现在自动安装 Node？" buttons {"去官网下载", "自动安装"} default button "自动安装" with title "CrossAgnetCoding")' 2>/dev/null)"
    if [ "$CHOICE" = "自动安装" ]; then
        echo "正在通过 Homebrew 安装 Node.js… / Installing Node.js via Homebrew…"
        brew install node
        hash -r 2>/dev/null || true
        command -v node >/dev/null 2>&1 && { echo "Node.js 安装完成 / installed: $(node --version)"; launch_gui; }
        echo "自动安装未成功，请手动安装后重试。 / Auto-install failed; please install manually and retry."
    fi
fi

echo "CrossAgnetCoding 需要 Node.js（建议 LTS）。请安装后重新打开本应用。"
echo "CrossAgnetCoding requires Node.js (LTS recommended). Please install it and reopen."
osascript -e 'display dialog "CrossAgnetCoding 需要 Node.js 运行。请安装 Node（建议 LTS）后重试。即将打开 nodejs.org。" buttons {"好"} default button 1 with title "CrossAgnetCoding"' >/dev/null 2>&1 || true
open "https://nodejs.org/" >/dev/null 2>&1 || true
echo ""
read -n 1 -s -r -p "Press any key to close…"
exit 1
SETUP_EOF
chmod +x "$APP_SRC_DIR/setup-node.command"
echo "  ✓ setup-node.command"

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

    # Prefer a macOS-style rounded (squircle) master so the Dock icon matches
    # native apps. Needs Pillow; falls back to the raw square source otherwise.
    ICON_MASTER="$ICON_SRC"
    ICON_STYLE="square (install Pillow for rounded corners)"
    if python3 -c "import PIL" >/dev/null 2>&1; then
        ROUNDED="$BUILD_DIR/icon_rounded.png"
        if python3 "$SCRIPT_DIR/make-rounded-icon.py" "$ICON_SRC" "$ROUNDED" 1024 >/dev/null 2>&1; then
            ICON_MASTER="$ROUNDED"
            ICON_STYLE="rounded macOS style"
        fi
    fi

    for SIZE in 16 32 128 256 512; do
        sips -z $SIZE $SIZE "$ICON_MASTER" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}.png" >/dev/null 2>&1
        DOUBLE=$((SIZE * 2))
        sips -z $DOUBLE $DOUBLE "$ICON_MASTER" --out "$ICONSET_DIR/icon_${SIZE}x${SIZE}@2x.png" >/dev/null 2>&1
    done
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns" 2>/dev/null
    rm -rf "$ICONSET_DIR"
    echo "  ✓ AppIcon.icns ($ICON_STYLE)"
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
