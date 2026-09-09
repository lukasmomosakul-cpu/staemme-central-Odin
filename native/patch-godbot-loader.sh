#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET"
mkdir -p app/src/main/assets
URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$URL" -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
a=s.index(' private void loadEnabledScripts(WebView v){')
b=s.index('\n @Override public void onBackPressed()',a)
new=r''' private void loadEnabledScripts(WebView v){
  String url=v.getUrl()==null?"":v.getUrl();
  // Never execute GodBot on login, home, or other landing pages.
  if(!url.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  try{
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));
   StringBuilder b=new StringBuilder(); String line;
   while((line=r.readLine())!=null)b.append(line).append(System.lineSeparator()); r.close();
   String src=b.toString();
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}window.GM_getValue=window.GM_getValue||function(k,d){return g(k,d)};window.GM_setValue=window.GM_setValue||function(k,v){s(k,v)};window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};window.GM_listValues=window.GM_listValues||function(){return[]};window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};window.unsafeWindow=window.unsafeWindow||window;window.GM_info=window.GM_info||{script:{name:'GodBot',version:'525'}};window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(GM_getValue(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){GM_setValue(k,v);return Promise.resolve()};})();";
   String q=JSONObject.quote(shim+System.lineSeparator()+src);
   String js="(function(){try{new Function("+q+")();console.log('ODIN_GODBOT_EVAL_OK')}catch(e){console.error('ODIN_GODBOT_EVAL_ERROR',e)}})()";
   v.evaluateJavascript(js,null);
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
 }
'''
p.write_text(s[:a]+new+s[b:])
PY
