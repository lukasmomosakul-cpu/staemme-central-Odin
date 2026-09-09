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

bypass = r'''\n private void bypassGodBotAccessGate(WebView v){String js="(function(){try{var rx=/(zugangscode|access\\s*code|zugang\\s*gesperrt|zugang\\s*verweigert|freischalt|activation\\s*code|license|lizenz)/i;function clean(){var all=document.querySelectorAll('body *');for(var i=0;i<all.length;i++){var e=all[i];if(e===document.body||e===document.documentElement)continue;var t=((e.innerText||'')+' '+(e.getAttribute('aria-label')||'')+' '+e.id+' '+e.className).trim();if(!t||t.length>800||!rx.test(t))continue;var c=getComputedStyle(e),r=e.getBoundingClientRect(),z=parseInt(c.zIndex||'0',10)||0;var overlay=(c.position==='fixed'||c.position==='absolute')&&(z>=50||(r.width>innerWidth*.55&&r.height>innerHeight*.25));if(overlay)e.remove();}var forms=document.querySelectorAll('form');for(var j=0;j<forms.length;j++){forms[j].style.pointerEvents='auto';forms[j].removeAttribute('aria-hidden');}var controls=document.querySelectorAll('input,button,select');for(var k=0;k<controls.length;k++){controls[k].removeAttribute('disabled');controls[k].removeAttribute('readonly');}}clean();new MutationObserver(clean).observe(document.documentElement,{subtree:true,childList:true,attributes:true});}catch(e){console.warn('[Odin] GodBot access gate cleanup failed',e);}})();";v.evaluateJavascript(js,null);}\n'''
marker = ' @Override public void onBackPressed()'
if marker not in s:
    raise SystemExit('GameWebViewActivity back-press marker not found')
s = s.replace(marker, bypass + marker, 1)
needle2 = 'loadEnabledScripts(v);}});'
if needle2 not in s:
    raise SystemExit('GodBot page-finished hook not found')
s = s.replace(needle2, 'loadEnabledScripts(v);bypassGodBotAccessGate(v);}});', 1)

p.write_text(s)
print(f'GodBot access gate cleanup added: {p}')
PY
