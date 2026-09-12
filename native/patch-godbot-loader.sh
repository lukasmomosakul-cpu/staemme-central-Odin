#!/usr/bin/env bash
set -euo pipefail
# Odin GodBot loader.
#
# Wichtig: GodBot ist ~730 KB. Ein String dieser Groesse durch
# WebView.evaluateJavascript zu schicken schlaegt still fehl (Binder-Limit).
# Deshalb wird nur ein kleiner Bootstrap injiziert, der die Quelle per fetch()
# aus der Seite heraus laedt. Nebeneffekt: das Gist wirkt immer sofort.
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" || { echo 'GodBot loader: GameWebViewActivity.java not found'; exit 1; }
VERSION=$(tr -d '[:space:]' < ../VERSION)
python3 - "$TARGET" "$VERSION" <<'PY'
from pathlib import Path
import sys, json

p = Path(sys.argv[1]); version = sys.argv[2]; s = p.read_text()
GIST = 'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'

js = r"""
(function(){try{
 if(window.__odinGodBot)return 'already'; window.__odinGodBot=1;
 var p='odin_gm_';
 function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}
 function st(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}
 window.unsafeWindow=window;
 window.GM_info=window.GM_info||{script:{name:'GodBot',version:'__VERSION__'}};
 window.GM_getValue=window.GM_getValue||g;
 window.GM_setValue=window.GM_setValue||st;
 window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};
 window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}catch(e){}return a};
 window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};
 window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){};
 window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){try{var z={status:200,responseText:OdinNative.httpGet(String(o.url)),response:''};z.response=z.responseText;if(o.onload)o.onload(z);return z}catch(e){if(o.onerror)o.onerror({status:0,error:e});return{abort:function(){}}}};
 function uiFix(){try{var V='__VERSION__';var A=document.querySelectorAll('*');for(var i=0;i<A.length;i++){var e=A[i],t=(e.textContent||'').trim();if(/USERSCRIPT OK/i.test(t)&&e.children.length===0){e.remove();continue}if(/loader aktiv/i.test(t)){e.style.width='fit-content';e.style.maxWidth='calc(100% - 24px)';e.style.display='inline-flex';e.style.boxSizing='border-box';e.style.padding='6px 10px';e.style.margin='8px';e.style.borderRadius='8px';e.style.position='relative'}}}catch(e){}}
 fetch('__GIST__',{cache:'no-store'}).then(function(r){return r.text()}).then(function(txt){
  if(!txt||txt.length<1000)throw new Error('source too short: '+(txt?txt.length:0));
  var reqs=[],m,re=/^\s*\/\/\s*@require\s+(\S+)/gm;
  while((m=re.exec(txt)))reqs.push(m[1]);
  return Promise.all(reqs.map(function(u){
   return fetch(u).then(function(r){return r.text()}).catch(function(){return ''});
  })).then(function(deps){
   for(var i=0;i<deps.length;i++){try{if(deps[i])(0,eval)(deps[i])}catch(e){console.error('ODIN_REQUIRE',e)}}
   (0,eval)(txt);
   uiFix();
   console.log('ODIN_GODBOT_LOADED chars='+txt.length+' deps='+deps.length);
  });
 }).catch(function(e){
  window.__odinGodBot=0;
  console.error('ODIN_GODBOT_FETCH_FAILED',e&&e.message?e.message:e);
 });
 return 'started';
}catch(e){window.__odinGodBot=0;console.error('ODIN_GODBOT_BOOT',e);return 'error'}})();
""".replace('__VERSION__', version).replace('__GIST__', GIST)

a = s.index(' private void loadEnabledScripts(WebView v){')
b = s.index('\n @Override public void onBackPressed()', a)

new = ''' private void loadEnabledScripts(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  // Tag haelt die URL, nicht nur ein Flag: sonst wird nach dem ersten
  // Seitenaufruf nie wieder injiziert.
  if(u.equals(v.getTag(0x0D1A0001)))return; v.setTag(0x0D1A0001,u); v.setTag(0x0D1A0002,null);
  android.util.Log.i("ODIN_GODBOT","page ready: "+u);
  for(long d:new long[]{2000L,5000L,9000L})v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},d);
 }
 private void executeGodBotWhenReady(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$"))return;
  // Bei aktiver Zugangssperre wird bewusst nichts injiziert, damit die
  // Captcha-Seite unveraendert bleibt. Marker aus dem echten Seitenquelltext.
  v.evaluateJavascript("(function(){try{return !!document.getElementById('botprotection_quest')}catch(e){return false}})()",bp->{
   if("true".equals(bp)){
    android.util.Log.i("ODIN_GODBOT","bot protection active - injection skipped");
    v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},15000L);
    return;
   }
   v.evaluateJavascript("(function(){try{return !!(document.body&&(window.game_data||window.TribalWars||document.querySelector('#content_value')))}catch(e){return false}})()",r->{if("true".equals(r))injectGodBot(v);});
  });
 }
 private void injectGodBot(WebView v){
  try{
   if(v.getTag(0x0D1A0002)!=null)return; v.setTag(0x0D1A0002,Boolean.TRUE);
   final String js=''' + json.dumps(js) + ''';
   android.util.Log.i("ODIN_GODBOT","injecting bootstrap, "+js.length()+" chars");
   v.evaluateJavascript(js,r->android.util.Log.i("ODIN_GODBOT","bootstrap returned "+r));
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","inject_failed",e);}
 }
'''

s = s[:a] + new + s[b:]
p.write_text(s)
print('GodBot loader: bootstrap injected (%d chars of JS)' % len(js))
PY
