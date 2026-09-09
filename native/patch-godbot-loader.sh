#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
mkdir -p app/src/main/assets

GODBOT_RAW='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$GODBOT_RAW" -o /tmp/godbot.user.js
test -s /tmp/godbot.user.js

python3 - <<'PY'
from pathlib import Path
import re, urllib.request
src=Path('/tmp/godbot.user.js').read_text(encoding='utf-8')
reqs=re.findall(r'^\s*//\s*@require\s+([^\s]+)', src, re.M)
out=[]
for url in reqs:
    try:
        with urllib.request.urlopen(url, timeout=30) as r:
            dep=r.read().decode('utf-8')
        out.append(f'// ODIN @require {url}\n{dep}\n')
    except Exception as e:
        raise SystemExit(f'Failed to download @require {url}: {e}')
Path('app/src/main/assets/godbot.user.js').write_text('\n'.join(out)+"\n"+src, encoding='utf-8')
print(f'GodBot source bytes: {len(src.encode())}; @require count: {len(reqs)}; bundled bytes: {Path("app/src/main/assets/godbot.user.js").stat().st_size}')
PY

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
  boolean inWorld=path.matches("(?i).*[/]game[.]php.*");
  if(!inWorld)return;
  new Thread(()->{
   try{
    BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\n');r.close();
    String source=b.toString();
    android.util.Log.i("ODIN_GODBOT","source_loaded bytes="+source.length()+" url="+path);
    String q=JSONObject.quote(source);
    runOnUiThread(()->{
     String runner="(function(){var CODE="+q+";function banner(text){try{var z=document.getElementById('__odin_godbot_status');if(!z){z=document.createElement('div');z.id='__odin_godbot_status';z.style='position:fixed;z.top:4px;z.right:4px;z.zIndex=2147483647;z.padding:5px 8px;background:#16202b;color:#fff;font:12px sans-serif;border:1px solid #4caf50;border-radius:4px;';document.documentElement.appendChild(z)}z.textContent=text}catch(e){}}function install(w){try{if(!w||!w.document)return 'no-window';if(w.__ODIN_GODBOT_LOADED__)return 'already';w.unsafeWindow=w;w.GM_info=w.GM_info||{script:{name:'GodBot',version:'Odin'},scriptHandler:'Odin',version:'1'};var gmPrefix='odin-gm:';w.GM_getValue=w.GM_getValue||function(k,d){try{var x=w.localStorage.getItem(gmPrefix+k);return x===null?d:JSON.parse(x)}catch(e){return d}};w.GM_setValue=w.GM_setValue||function(k,val){try{w.localStorage.setItem(gmPrefix+k,JSON.stringify(val))}catch(e){}};w.GM_deleteValue=w.GM_deleteValue||function(k){try{w.localStorage.removeItem(gmPrefix+k)}catch(e){}};w.GM_listValues=w.GM_listValues||function(){try{var a=[];for(var i=0;i<w.localStorage.length;i++){var k=w.localStorage.key(i);if(k&&k.indexOf(gmPrefix)===0)a.push(k.slice(gmPrefix.length))}return a}catch(e){return[]}};w.GM_addStyle=w.GM_addStyle||function(css){try{var z=w.document.createElement('style');z.textContent=css;w.document.documentElement.appendChild(z);return z}catch(e){return null}};w.GM_setClipboard=w.GM_setClipboard||function(x){try{if(w.navigator.clipboard&&w.navigator.clipboard.writeText)return w.navigator.clipboard.writeText(String(x))}catch(e){}};w.GM_openInTab=w.GM_openInTab||function(u){try{return w.open(u,'_blank')}catch(e){return null}};w.GM_notification=w.GM_notification||function(x){try{w.console&&w.console.log('ODIN_GM_NOTIFICATION',x)}catch(e){}};w.GM_registerMenuCommand=w.GM_registerMenuCommand||function(){return null};w.GM_xmlhttpRequest=w.GM_xmlhttpRequest||function(o){try{var x=new XMLHttpRequest();x.open(o.method||'GET',o.url,true);x.onload=function(){o.onload&&o.onload({responseText:x.responseText,response:x.response,status:x.status,statusText:x.statusText,finalUrl:x.responseURL})};x.onerror=function(){o.onerror&&o.onerror({status:x.status,statusText:x.statusText})};x.send(o.data||null);return x}catch(e){o.onerror&&o.onerror({error:e});return null}};w.GM_getResourceText=w.GM_getResourceText||function(){return null};w.GM_getResourceURL=w.GM_getResourceURL||function(){return null};w.GM_addValueChangeListener=w.GM_addValueChangeListener||function(){return 0};w.GM_removeValueChangeListener=w.GM_removeValueChangeListener||function(){};w.GM=w.GM||{};w.GM.getValue=w.GM.getValue||function(k,d){return Promise.resolve(w.GM_getValue(k,d))};w.GM.setValue=w.GM.setValue||function(k,v){w.GM_setValue(k,v);return Promise.resolve()};w.GM.deleteValue=w.GM.deleteValue||function(k){w.GM_deleteValue(k);return Promise.resolve()};w.GM.listValues=w.GM.listValues||function(){return Promise.resolve(w.GM_listValues())};banner('GodBot: eval gestartet');android.util.Log.i('ODIN_GODBOT','eval_started');(0,w.eval)(CODE);w.__ODIN_GODBOT_LOADED__=true;banner('GodBot: eval OK');return 'injected'}catch(e){try{w.console&&w.console.error('ODIN_GODBOT_INJECTION_ERROR',e)}catch(_){ }banner('GodBot: FEHLER');return 'error:'+(e&&e.stack?e.stack:(e&&e.message?e.message:String(e)))}}function attempt(n){var result=install(window);try{for(var i=0;i<window.frames.length;i++)install(window.frames[i])}catch(e){}if(result==='injected'||result==='already')return result;if(n<10){setTimeout(function(){attempt(n+1)},500);return 'retry'}return result}return attempt(0)})()";
     v.evaluateJavascript(runner,value->android.util.Log.i("ODIN_GODBOT","loader_result="+value+" url="+v.getUrl()));
    });
   }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
  }).start();
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
