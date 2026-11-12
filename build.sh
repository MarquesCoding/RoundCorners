#!/bin/zsh
# Builds RoundCorners.app (menu-bar only, no Dock icon) into ./build
set -e
cd "${0:A:h}"
swift build -c release
APP=build/RoundCorners.app
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
cp .build/release/RoundCorners "$APP/Contents/MacOS/"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>RoundCorners</string>
  <key>CFBundleIdentifier</key><string>local.roundcorners</string>
  <key>CFBundleExecutable</key><string>RoundCorners</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>26.0</string>
  <key>LSUIElement</key><true/>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "Built $APP"
