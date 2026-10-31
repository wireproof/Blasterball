#!/bin/sh
set -eu
cd "$(dirname "$0")"
MODE="${1:-device}"
if [ "$MODE" = simulator ]; then
  PLATFORM=iphonesimulator
  TARGET=arm64-apple-ios16.0-simulator
  APP="$PWD/build/Simulator/Blasterball.app"
else
  PLATFORM=iphoneos
  TARGET=arm64-apple-ios16.0
  APP="$PWD/build/Payload/Blasterball.app"
fi
SDK="$(xcrun --sdk "$PLATFORM" --show-sdk-path)"
mkdir -p "$APP" "$PWD/build/module-cache-v12"
xcrun --sdk "$PLATFORM" swiftc -parse-as-library *.swift -sdk "$SDK" -target "$TARGET" -module-cache-path "$PWD/build/module-cache-v12" -O -framework UIKit -framework SpriteKit -o "$APP/Blasterball"
cp Resources/*.json "$APP/"
cp -R Resources/Editions Resources/Campaigns Resources/Audio Resources/Menu Resources/BB3 "$APP/"
xcrun actool "$PWD/Assets.xcassets" --compile "$APP" --platform "$PLATFORM" --minimum-deployment-target 16.0 --app-icon AppIcon --output-partial-info-plist "$PWD/build/icons-$PLATFORM.plist" --target-device iphone --target-device ipad > "$PWD/build/actool-$PLATFORM.log" 2>&1
python3 - "$APP" "$PWD/build/icons-$PLATFORM.plist" <<'PY'
import sys,plistlib,pathlib
app=pathlib.Path(sys.argv[1]);d=plistlib.loads(pathlib.Path('Info.plist').read_bytes())
d.update(plistlib.loads(pathlib.Path(sys.argv[2]).read_bytes()))
(app/'Info.plist').write_bytes(plistlib.dumps(d))
PY
/usr/bin/codesign --force --sign - "$APP"
/usr/bin/codesign --verify --strict "$APP"
/usr/bin/plutil -lint "$APP/Info.plist"
if [ "$MODE" != simulator ]; then
  python3 - <<'PY'
from pathlib import Path
import zipfile,hashlib
p=Path('build/Blasterball-0.6.0-build13.ipa')
with zipfile.ZipFile(p,'w',zipfile.ZIP_DEFLATED) as z:
    for f in sorted(Path('build/Payload').rglob('*')):
        if f.is_file(): z.write(f,f.relative_to('build'))
with zipfile.ZipFile(p) as z: assert z.testzip() is None
digest=hashlib.sha256(p.read_bytes()).hexdigest()
p.with_suffix('.sha256').write_text(f'{digest}  {p.name}\n')
print(digest,p)
PY
fi
