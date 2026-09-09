#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()

needle = 'if(sj!=null)try{JSONArray a=new JSONArray(sj);for(int i=0;i<a.length();i++){String src=a.getJSONObject(i).optString("source","");if(src.startsWith("https://"))managedScripts.add(src);}}catch(Exception ignored){}'
if needle not in s:
    raise SystemExit('GodBot insertion point not found')
s = s.replace(needle, needle + ' managedScripts.add(GODBOT_URL);', 1)

# GodBot must only run on actual game pages. Never force it on the login/landing page.
s = s.replace('boolean godbot=GODBOT_URL.equalsIgnoreCase(source);if(!inWorld&&!godbot)continue;', 'if(!inWorld)continue;', 1)

# IMPORTANT: do not manipulate or remove any access/login page DOM.
# The previous access-gate cleanup could destroy the page immediately after load.

p.write_text(s)
print(f'GodBot native loader patched without access-gate DOM manipulation: {p}')
PY
