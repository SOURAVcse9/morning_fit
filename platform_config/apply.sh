#!/usr/bin/env bash
# Run from the project root AFTER `flutter create` (see README step 1).
set -euo pipefail
cp platform_config/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp platform_config/ios/AppDelegate.swift ios/Runner/AppDelegate.swift
python3 - <<'PY'
import re
p='ios/Runner/Info.plist'
s=open(p).read()
add=open('platform_config/ios/Info.plist.additions.xml').read()
add='\n'.join(l for l in add.splitlines() if not l.strip().startswith('<!--'))
if 'NSMotionUsageDescription' not in s:
    s=s.replace('</dict>\n</plist>', add+'\n</dict>\n</plist>')
    open(p,'w').write(s)
    print('Info.plist updated')
else:
    print('Info.plist already configured')
PY
echo "Platform configuration applied."
