#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
mkdir -p app/src/main/assets

# GodBot is bundled into the APK at build time. Runtime must not depend on the Gist.
GODBOT_RAW='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$GODBOT_RAW" -o app/src/main/assets/godbot.user.js
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
    BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();
    String q=JSONObject.quote(b.toString());
    runOnUiThread(()->{
     String runner="(function(){var CODE="+q+";function install(w){try{if(!w||!w.document)return 'no-window';if(w.__ODIN_GODBOT_LOADED__)return 'already';w.unsafeWindow=w;w.GM_info=w.GM_info||{script:{name:'GodBot',version:'Odin'},scriptHandler:'Odin',version:'1'};w.GM_getValue=w.GM_getValue||function(k,d){try{var x=w.localStorage.getItem('odin-gm:'+k);return x===null?d:JSON.parse(x)}catch(e){return d}};w.GM_setValue=w.GM_setValue||function(k,val){try{w.localStorage.setItem('odin-gm:'+k,JSON.stringify(val))}catch(e){}};w.GM_deleteValue=w.GM_deleteValue||function(k){try{w.localStorage.removeItem('odin-gm:'+k)}catch(e){}};w.GM_listValues=w.GM_listValues||function(){try{var a=[],p='odin-gm:';for(var i=0;i<w.localStorage.length;i++){var k=w.localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}return a}catch(e){return[]}};w.GM_addStyle=w.GM_addStyle||function(css){try{var z=w.document.createElement('style');z.textContent=css;w.document.documentElement.appendChild(z);return z}catch(e){return null}};w.GM_setClipboard=w.GM_setClipboard||function(x){try{if(w.navigator.clipboard&&w.navigator.clipboard.writeText)w.navigator.clipboard.writeText(String(x))}catch(e){}};w.GM_openInTab=w.GM_openInTab||function(u){try{return w.open(u,'_blank')}catch(e){return null}};w.GM_notification=w.GM_notification||function(x){try{w.console&&w.console.log('Odin notification',x)}catch(e){}};w.GM_registerMenuCommand=w.GM_registerMenuCommand||function(){return null};(0,w.eval)(CODE);w.__ODIN_GODBOT_LOADED__=true;return 'injected'}catch(e){try{w.console&&w.console.error('ODIN GodBot injection error',e)}catch(_){ }return 'error:'+(e&&e.stack?e.stack:(e&&e.message?e.message:String(e)))}}function attempt(n){var result=install(window);try{for(var i=0;i<window.frames.length;i++)install(window.frames[i])}catch(e){}if(result==='injected'||result==='already'){if(w&&w.clearTimeout){}return result}if(n<5){setTimeout(function(){attempt(n+1)},500);return 'retry'}return result}var w=window;return attempt(0)})()";
     v.evaluateJavascript(runner,value->android.util.Log.d("ODIN_GODBOT","loader="+value+" url="+v.getUrl()));
    });
   }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset load failed",e);runOnUiThread(()->android.widget.Toast.makeText(GameWebViewActivity.this,"GodBot konnte nicht aus dem App-Bundle geladen werden",android.widget.Toast.LENGTH_LONG).show());}
  }).start();
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY