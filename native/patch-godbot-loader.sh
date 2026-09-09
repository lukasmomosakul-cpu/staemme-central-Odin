#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
mkdir -p app/src/main/assets

GODBOT_URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
if command -v curl >/dev/null 2>&1; then
  curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$GODBOT_URL" -o app/src/main/assets/godbot.user.js
else
  python3 - "$GODBOT_URL" app/src/main/assets/godbot.user.js <<'PY'
import sys, urllib.request
url, out = sys.argv[1:]
with urllib.request.urlopen(url, timeout=60) as r:
    data = r.read()
open(out, 'wb').write(data)
PY
fi
test -s app/src/main/assets/godbot.user.js

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys

p = Path(sys.argv[1])
s = p.read_text()
start = s.index(' private void loadEnabledScripts(WebView v){')
end = s.index('\n @Override public void onBackPressed()', start)

new = r''' private void loadEnabledScripts(WebView v){
  String path=v.getUrl()==null?"":v.getUrl();
  if(!path.matches("(?i).*[/]game[.]php.*"))return;
  try{
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();
   String source=b.toString();
   android.util.Log.i("ODIN_GODBOT","bundled_source bytes="+source.length()+" url="+path);
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}window.GM_getValue=window.GM_getValue||function(k,d){return g(k,d)};window.GM_setValue=window.GM_setValue||function(k,v){s(k,v)};window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}catch(e){}return a};window.GM_addStyle=window.GM_addStyle||function(css){var st=document.createElement('style');st.textContent=css;(document.head||document.documentElement).appendChild(st);return st};window.GM_openInTab=window.GM_openInTab||function(u){return window.open(u,'_blank')};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){return 0};window.GM_notification=window.GM_notification||function(o){try{if(typeof o==='string')alert(o);else if(o&&o.text)alert(o.text)}catch(e){}};window.GM_setClipboard=window.GM_setClipboard||function(t){try{navigator.clipboard.writeText(String(t))}catch(e){}};window.GM_info=window.GM_info||{script:{name:'GodBot',namespace:'odin',version:'525',grant:[]},scriptMetaStr:''};window.unsafeWindow=window.unsafeWindow||window;window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(window.GM_getValue(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){window.GM_setValue(k,v);return Promise.resolve()};window.GM.deleteValue=window.GM.deleteValue||function(k){window.GM_deleteValue(k);return Promise.resolve()};window.GM.listValues=window.GM.listValues||function(){return Promise.resolve(window.GM_listValues())};window.GM.addStyle=window.GM.addStyle||function(c){return Promise.resolve(window.GM_addStyle(c))};window.GM.openInTab=window.GM.openInTab||function(u){return Promise.resolve(window.GM_openInTab(u))};window.GM.registerMenuCommand=window.GM.registerMenuCommand||function(){return Promise.resolve(window.GM_registerMenuCommand.apply(null,arguments))};})();";
   String q=JSONObject.quote(shim+"\\n"+source);
   String runner="(function(){try{var CODE="+q+";var fn=new Function(CODE);fn();console.log('ODIN_GODBOT_EVAL_OK');return 'injected'}catch(e){console.error('ODIN_GODBOT_EVAL_ERROR',e);return 'error:'+(e&&e.stack?e.stack:(e&&e.message?e.message:String(e)))}})()";
   v.evaluateJavascript(runner,value->android.util.Log.i("ODIN_GODBOT","loader_result="+value+" url="+v.getUrl()));
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
