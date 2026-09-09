#!/usr/bin/env bash
set -euo pipefail

TARGET="app/src/main/java/$(find app/src/main -type f -name 'GameWebViewActivity.java' -printf '%P\n' | head -n1)"
# The generated Java file is already under the package directory; find it robustly.
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()
needle = 'if(sj!=null)try{JSONArray a=new JSONArray(sj);for(int i=0;i<a.length();i++){String src=a.getJSONObject(i).optString("source","");if(src.startsWith("https://"))managedScripts.add(src);}}catch(Exception ignored){}'
insert = needle + ' managedScripts.add(GODBOT_URL);'
if needle not in s:
    raise SystemExit('GodBot insertion point not found')
s = s.replace(needle, insert, 1)
s = s.replace('boolean godbot=GODBOT_URL.equalsIgnoreCase(source);if(!inWorld&&!godbot)continue;', 'if(!inWorld)continue;', 1)
p.write_text(s)
print(f'GodBot fixed loader patched: {p}')
PY
