#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
mkdir -p app/src/main/assets

GODBOT_URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
ASSET='app/src/main/assets/godbot.user.js'
if command -v curl >/dev/null 2>&1; then
  curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$GODBOT_URL" -o "$ASSET"
else
  python3 - "$GODBOT_URL" "$ASSET" <<'PY'
import sys, urllib.request
url, out = sys.argv[1:]
with urllib.request.urlopen(url, timeout=60) as r:
    data = r.read()
open(out, 'wb').write(data)
PY
fi
test -s "$ASSET"

python3 - "$ASSET" <<'PY'
from pathlib import Path
import re, subprocess, sys
p=Path(sys.argv[1])
s=p.read_text(errors='replace')
reqs=re.findall(r'^\s*//\s*@require\s+(\S+)\s*$',s,re.M)
out=[]
for i,u in enumerate(reqs,1):
    try:
        data=subprocess.check_output(['curl','-fsSL','--retry','3','--connect-timeout','15','--max-time','60',u],text=True,stderr=subprocess.STDOUT)
        out.append('\n/* ODIN @require %d: %s */\n%s\n/* END ODIN @require %d */\n' % (i,u,data,i))
    except Exception as e:
        raise SystemExit('Could not download @require %s: %s' % (u,e))
if out:
    p.write_text(''.join(out)+s)
    print('Bundled',len(out),'@require dependencies')
else:
    print('GodBot has no @require dependencies')
PY

test -s "$ASSET"

python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
start=s.index(' private void loadEnabledScripts(WebView v){')
end=s.index('\n @Override public void onBackPressed()',start)
new=r''' private void loadEnabledScripts(WebView v){
  String path=v.getUrl()==null?"":v.getUrl();
  if(!path.matches("(?i)^https?://([^.]+[.]*)?die-staemme[.]de(/.*)?$"))return;
  try{
   if(v.getUrl()!=null && v.getUrl().equals(path)){
    v.evaluateJavascript("(function(){window.__odinGodBotAttempt=(window.__odinGodBotAttempt||0)+1;return window.__odinGodBotAttempt})()",null);
   }
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append(System.lineSeparator());r.close();
   String source=b.toString();
   android.util.Log.i("ODIN_GODBOT","bundled_source bytes="+source.length()+" url="+path);
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}window.GM_getValue=window.GM_getValue||function(k,d){return g(k,d)};window.GM_setValue=window.GM_setValue||function(k,v){s(k,v)};window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}catch(e){}return a};window.GM_addStyle=window.GM_addStyle||function(css){var st=document.createElement('style');st.textContent=css;(document.head||document.documentElement).appendChild(st);return st};window.GM_openInTab=window.GM_openInTab||function(u){return window.open(u,'_blank')};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){return 0};window.GM_notification=window.GM_notification||function(o){try{if(typeof o==='string')alert(o);else if(o&&o.text)alert(o.text)}catch(e){}};window.GM_setClipboard=window.GM_setClipboard||function(t){try{navigator.clipboard.writeText(String(t))}catch(e){}};window.GM_info=window.GM_info||{script:{name:'GodBot',namespace:'odin',version:'525',grant:[]},scriptMetaStr:''};window.unsafeWindow=window.unsafeWindow||window;window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(window.GM_getValue(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){window.GM_setValue(k,v);return Promise.resolve()};window.GM.deleteValue=window.GM.deleteValue||function(k){window.GM_deleteValue(k);return Promise.resolve()};window.GM.listValues=window.GM.listValues||function(){return Promise.resolve(window.GM_listValues())};window.GM.addStyle=window.GM.addStyle||function(c){return Promise.resolve(window.GM_addStyle(c))};window.GM.openInTab=window.GM.openInTab||function(u){return Promise.resolve(window.GM_openInTab(u))};window.GM.registerMenuCommand=window.GM.registerMenuCommand||function(){return Promise.resolve(window.GM_registerMenuCommand.apply(null,arguments))};function xhr(o){var x=new XMLHttpRequest();x.open(o.method||'GET',o.url,true);if(o.headers)for(var k in o.headers)try{x.setRequestHeader(k,o.headers[k])}catch(e){}x.onload=function(){var r={status:x.status,statusText:x.statusText,responseText:x.responseText,response:x.responseText,finalUrl:x.responseURL,readyState:4};if(o.onload)o.onload(r)};x.onerror=function(e){if(o.onerror)o.onerror({error:e,readyState:4})};x.onreadystatechange=function(){if(o.onreadystatechange)o.onreadystatechange({readyState:x.readyState,status:x.status,responseText:x.responseText})};try{x.send(o.data||null)}catch(e){if(o.onerror)o.onerror({error:e})}return {abort:function(){try{x.abort()}catch(e){}}}}window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||xhr;window.GM.xmlHttpRequest=window.GM.xmlHttpRequest||function(o){return Promise.resolve(xhr(o))};})();";
   String payload=shim+System.lineSeparator()+source;
   String q=JSONObject.quote(payload);
   String runner="(function(){try{var CODE="+q+";var fn=new Function(CODE);fn();console.log('ODIN_GODBOT_EVAL_OK');return 'injected'}catch(e){console.error('ODIN_GODBOT_EVAL_ERROR',e);return 'error:'+(e&&e.stack?e.stack:(e&&e.message?e.message:String(e)))}})()";
   v.evaluateJavascript(runner,value->android.util.Log.i("ODIN_GODBOT","loader_result="+value+" url="+v.getUrl()));
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
