#!/usr/bin/env bash
set -euo pipefail

MANIFEST=$(find android/app/src/main -name AndroidManifest.xml -type f | head -n1)
test -n "$MANIFEST"
RES="android/app/src/main/res"
mkdir -p "$RES/drawable"

cat > "$RES/drawable/odin_icon.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF" android:pathData="M23,20 L29,14 L94,79 L88,85 Z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M85,14 L91,20 L26,85 L20,79 Z" />
    <path android:fillColor="#B8893F" android:pathData="M17,76 L31,90 L26,95 L12,81 Z" />
    <path android:fillColor="#B8893F" android:pathData="M77,90 L91,76 L96,81 L82,95 Z" />
    <path android:fillColor="#8A6A35" android:pathData="M12,76 L18,70 L37,89 L31,95 Z" />
    <path android:fillColor="#8A6A35" android:pathData="M71,89 L90,70 L96,76 L77,95 Z" />
    <path android:fillColor="#B8893F" android:pathData="M68,20 L88,40 L82,46 L62,26 Z" />
    <path android:fillColor="#B8893F" android:pathData="M20,40 L40,20 L46,26 L26,46 Z" />
</vector>
EOF

python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1])
s=p.read_text()
s=s.replace('android:icon="@mipmap/ic_launcher"','android:icon="@drawable/odin_icon"')
s=s.replace('android:roundIcon="@mipmap/ic_launcher_round"','android:roundIcon="@drawable/odin_icon"')
if 'android:icon="@drawable/odin_icon"' not in s:
    s=s.replace('<application ', '<application android:icon="@drawable/odin_icon" android:roundIcon="@drawable/odin_icon" ',1)
p.write_text(s)
PY

echo 'Odin launcher icon applied: crossed swords (⚔)'
