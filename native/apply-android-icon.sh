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
    <path android:fillColor="#182230" android:pathData="M0,0h108v108h-108z" />
    <!-- sword from lower-left to upper-right -->
    <path android:fillColor="#F3F6FA" android:pathData="M18,82 L25,89 L84,30 L78,24 Z" />
    <path android:fillColor="#B8893F" android:pathData="M72,18 L90,36 L84,42 L66,24 Z" />
    <path android:fillColor="#D8DEE7" android:pathData="M81,21 L87,27 L34,80 L30,76 Z" />
    <path android:fillColor="#B8893F" android:pathData="M20,76 L34,90 L29,95 L15,81 Z" />
    <path android:fillColor="#8A6A35" android:pathData="M14,78 L20,72 L36,88 L30,94 Z" />
    <!-- sword from upper-left to lower-right -->
    <path android:fillColor="#F3F6FA" android:pathData="M24,24 L30,18 L89,77 L83,83 Z" />
    <path android:fillColor="#D8DEE7" android:pathData="M21,21 L27,15 L80,68 L76,72 Z" />
    <path android:fillColor="#B8893F" android:pathData="M66,84 L84,66 L90,72 L72,90 Z" />
    <path android:fillColor="#8A6A35" android:pathData="M78,76 L84,70 L94,80 L88,86 Z" />
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
    s=s.replace('<application ', '<application android:icon="@drawable/odin_icon" android:roundIcon="@drawable/odin_icon" ' ,1)
p.write_text(s)
PY

echo 'Odin launcher icon applied: crossed swords (⚔)'
