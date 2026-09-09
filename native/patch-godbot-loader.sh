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
  if(managedScripts.isEmpty() && GODBOT_URL.isEmpty())return;
  String path=v.getUrl()==null?"":v.getUrl();
  boolean inWorld=path.matches("(?i).*[/]game[.]php.*");
  if(!inWorld)return;
  new Thread(()->{
   try{
    BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();
    String q=JSONObject.quote(b.toString());
    runOnUiThread(()->{
     String runner="(function(){var CODE="+q+";function install(w){try{if(!w||!w.document)return;if(w.__ODIN_GODBOT_LOADED__)return;w.__ODIN_GODBOT_LOADED__=true;w.__ODIN_DISABLE_GODBOT_GATE__=true;w.unsafeWindow=w;w.GM_info=w.GM_info||{script:{name:'GodBot',version:'Odin'},scriptHandler:'Odin',version:'1'};w.GM_getValue=w.GM_getValue||function(k,d){try{var x=w.localStorage.getItem('odin-gm:'+k);return x===null?d:JSON.parse(x)}catch(e){return d}};w.GM_setValue=w.GM_setValue||function(k,val){try{w.localStorage.setItem('odin-gm:'+k,JSON.stringify(val))}catch(e){}};w.GM_deleteValue=w.GM_deleteValue||function(k){try{w.localStorage.removeItem('odin-gm:'+k)}catch(e){}};w.GM_listValues=w.GM_listValues||function(){return[]};w.GM_addStyle=w.GM_addStyle||function(css){try{var z=w.document.createElement('style');z.textContent=css;w.document.documentElement.appendChild(z);return z}catch(e){return null}};w.GM_setClipboard=w.GM_setClipboard||function(x){try{if(w.navigator.clipboard&&w.navigator.clipboard.writeText)w.navigator.clipboard.writeText(String(x))}catch(e){}};w.GM_openInTab=w.GM_openInTab||function(u){try{return w.open(u,'_blank')}catch(e){return null}};w.GM_notification=w.GM_notification||function(x){try{w.console&&w.console.log('Odin notification',x)}catch(e){}};w.GM_registerMenuCommand=w.GM_registerMenuCommand||function(){return null};try{(0,w.eval)(CODE)}catch(e){try{w.console&&w.console.error('Odin GodBot error',e)}catch(_){}}}catch(e){}}install(w);try{for(var i=0;i<w.frames.length;i++)install(w.frames[i])}catch(e){}var n=0;function gate(){try{if(!w.document||!w.document.body)return;var els=w.document.querySelectorAll('body *');for(var i=0;i<els.length;i++){var e=els[i],t=(e.innerText||e.textContent||'').trim();if(!t||t.length>400)continue;if(/(?:godbot|odin).{0,80}(?:passwort|zugangscode|freischalt|sperre)|(?:passwort|zugangscode|freischalt|sperre).{0,80}(?:godbot|odin)/i.test(t)){var cs=getComputedStyle(e);if(cs.position==='fixed'||cs.position==='absolute'||Number(cs.zIndex||0)>100){e.remove();}}}}catch(e){}}install(w);var g=setInterval(gate,500);setTimeout(function(){clearInterval(g)},30000)})();";
     v.evaluateJavascript(runner,null);
    });
   }catch(Exception e){runOnUiThread(()->android.widget.Toast.makeText(GameWebViewActivity.this,"GodBot konnte nicht aus dem App-Bundle geladen werden",android.widget.Toast.LENGTH_LONG).show());}
  }).start();
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
