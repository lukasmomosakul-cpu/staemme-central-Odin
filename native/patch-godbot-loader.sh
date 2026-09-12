#!/usr/bin/env bash
set -euo pipefail
# Odin GodBot loader.
#
# Zwei Grenzen bestimmen dieses Design:
#  1. GodBot ist ~730 KB. So ein String durch WebView.evaluateJavascript zu
#     schicken schlaegt still fehl (Binder-Limit).
#  2. Die Spielseite kann per CSP (connect-src) ein fetch() auf fremde Hosts
#     blockieren.
# Deshalb wird das Skript ueber shouldInterceptRequest unter der GLEICHEN
# Origin ausgeliefert (/__odin_godbot.js) und per <script src> eingebunden.
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" || { echo 'GodBot loader: GameWebViewActivity.java not found'; exit 1; }
mkdir -p app/src/main/assets
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 \
  'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js' \
  -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
rm -f app/src/main/assets/odin-test.user.js
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
 // Ein Fehler beim Auswerten von GodBot wuerde sonst nur in der Konsole landen.
 // Ersten Fehler festhalten. Frueher wurde die Meldung von der spaeteren
 // Statuspruefung ueberschrieben - genau die Information ging dabei verloren.
 window.addEventListener('error',function(ev){try{if(window.__odinErrMsg)return;
  var m=(ev.error&&ev.error.message)||ev.message||'?';
  var w=(ev.filename||'')+':'+(ev.lineno||0);
  window.__odinErrMsg='JS-Fehler: '+m+' @'+w;
  OdinNative.status(window.__odinErrMsg);}catch(e){}},true);
 window.addEventListener('unhandledrejection',function(ev){try{if(window.__odinErrMsg)return;
  window.__odinErrMsg='Promise-Fehler: '+(ev.reason&&ev.reason.message?ev.reason.message:ev.reason);
  OdinNative.status(window.__odinErrMsg);}catch(e){}});
 // GodBot richtet Bruecken wie Object.defineProperty(window,'Timing',{get:...})
 // ein. Unter Tampermonkey laufen die in einer Sandbox, hier im Seitenkontext
 // hat das Spiel 'Timing' bereits nicht-konfigurierbar definiert -> TypeError,
 // und das Skript bricht in Zeile 24 ab. Deshalb fuer window tolerant machen.
 if(!window.__odinDefineFix){
  window.__odinDefineFix=1;
  var _odp=Object.defineProperty;
  Object.defineProperty=function(o,prop,desc){
   try{ return _odp(o,prop,desc); }
   catch(err){
    if(o!==window)throw err;
    try{
     var val = desc && (('value' in desc) ? desc.value : (desc.get ? desc.get() : undefined));
     if(val!==undefined) o[prop]=val;
    }catch(e2){}
    try{OdinNative.status('Bruecke uebersprungen: '+prop);}catch(e3){}
    return o;
   }
  };
 }
 var n=__DEPCOUNT__, urls=[];
 for(var i=0;i<n;i++)urls.push('/__odin_req_'+i+'.js');
 urls.push('/__odin_godbot.js');
 var done=0;
 function add(i){
  if(i>=urls.length){
   try{var V='__VERSION__';var A=document.querySelectorAll('*');for(var k=0;k<A.length;k++){var e=A[k],t=(e.textContent||'').trim();if(/USERSCRIPT OK/i.test(t)&&e.children.length===0){e.remove();continue}if(/loader aktiv/i.test(t)){e.style.width='fit-content';e.style.maxWidth='calc(100% - 24px)';e.style.display='inline-flex';e.style.padding='6px 10px';e.style.margin='8px';e.style.borderRadius='8px'}}}catch(e){}
   // window.godbotCommands wird von GodBot gesetzt - damit laesst sich
   // 'Datei geladen' von 'Skript wirklich durchgelaufen' unterscheiden.
   function verdict(){try{
    if(window.__odinErrMsg){OdinNative.status(window.__odinErrMsg);return;}
    if(typeof window.godbotCommands==='function'){OdinNative.status('aktiv ('+done+' Teile)');return;}
    // Kein Fehler geworfen: das Skript lief durch, nur der Marker fehlt.
    OdinNative.status('ausgefuehrt, kein Fehler (Marker fehlt)');
   }catch(e){}}
   setTimeout(verdict,3000); setTimeout(verdict,12000);
   OdinNative.status('geladen ('+done+' Teile), pruefe...');
   return;
  }
  var sc=document.createElement('script');
  sc.src=urls[i]; sc.async=false;
  sc.onload=function(){done++;add(i+1)};
  sc.onerror=function(){OdinNative.status('Fehler bei '+urls[i]);window.__odinGodBot=0};
  (document.head||document.documentElement).appendChild(sc);
 }
 OdinNative.status('injiziere...');
 add(0);
 return 'started';
}catch(e){window.__odinGodBot=0;try{OdinNative.status('Bootstrap-Fehler: '+e.message)}catch(_){}return 'error'}})();
""".replace('__VERSION__', version)

a = s.index(' private void loadEnabledScripts(WebView v){')
b = s.index('\n @Override public void onWindowFocusChanged', a)

new = ''' private void loadEnabledScripts(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  if(u.equals(v.getTag(0x0D1A0001)))return; v.setTag(0x0D1A0001,u); v.setTag(0x0D1A0002,null);
  setStatus("Seite bereit");
  for(long d:new long[]{2000L,5000L,9000L})v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},d);
 }
 private void executeGodBotWhenReady(WebView v){
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$"))return;
  // Bei aktiver Zugangssperre bewusst nichts injizieren, damit die Captcha-
  // Seite unveraendert bleibt. Marker aus dem echten Seitenquelltext.
  v.evaluateJavascript("(function(){try{return !!document.getElementById('botprotection_quest')}catch(e){return false}})()",bp->{
   if("true".equals(bp)){
    setStatus("Zugangssperre aktiv - pausiert");
    v.postDelayed(()->{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);},15000L);
    return;
   }
   v.evaluateJavascript("(function(){try{return !!(document.body&&(window.game_data||window.TribalWars||document.querySelector('#content_value')))}catch(e){return false}})()",r->{if("true".equals(r))injectGodBot(v);});
  });
 }
 private void injectGodBot(WebView v){
  if(v.getTag(0x0D1A0002)!=null)return; v.setTag(0x0D1A0002,Boolean.TRUE);
  new Thread(()->{
   try{
    setStatus("lade Quelle...");
    String src=new OdinNative().httpGet(GODBOT_URL);
    if(src==null||src.length()<1000){setStatus("Quelle zu kurz ("+(src==null?0:src.length())+")");return;}
    java.util.List<String> deps=new java.util.ArrayList<>();
    java.util.regex.Matcher m=java.util.regex.Pattern.compile("(?m)^\\\\s*//\\\\s*@require\\\\s+(\\\\S+)").matcher(src);
    while(m.find()){try{deps.add(new OdinNative().httpGet(m.group(1)));}catch(Exception ig){deps.add("");}}
    godbotSrc=src; godbotDeps=deps;
    setStatus("Quelle bereit ("+src.length()+" Z., "+deps.size()+" Abh.)");
    final String js=''' + json.dumps(js) + '''.replace("__DEPCOUNT__",String.valueOf(deps.size()));
    runOnUiThread(()->v.evaluateJavascript(js,r->android.util.Log.i("ODIN_GODBOT","bootstrap="+r)));
   }catch(Exception e){
    setStatus("Abruf fehlgeschlagen: "+e.getMessage());
    v.setTag(0x0D1A0002,null);
   }
  }).start();
 }
 // Liefert die Skripte unter der Origin der Spielseite aus: umgeht CSP
 // (connect-src) und das Groessenlimit von evaluateJavascript.
 private WebResourceResponse odinIntercept(WebResourceRequest r){
  try{
   String path=r.getUrl().getPath(); if(path==null)return null;
   String body=null;
   if(path.equals("/__odin_godbot.js"))body=godbotSrc;
   else if(path.startsWith("/__odin_req_")){
    int i=Integer.parseInt(path.substring(12,path.length()-3));
    java.util.List<String> d=godbotDeps; if(i>=0&&i<d.size())body=d.get(i);
   }
   if(body==null)return null;
   java.util.Map<String,String> h=new java.util.HashMap<>();
   h.put("Access-Control-Allow-Origin","*"); h.put("Cache-Control","no-store");
   WebResourceResponse res=new WebResourceResponse("application/javascript","utf-8",
     new java.io.ByteArrayInputStream(body.getBytes("UTF-8")));
   res.setStatusCodeAndReasonPhrase(200,"OK"); res.setResponseHeaders(h);
   return res;
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","intercept",e);return null;}
 }
'''

s = s.replace(' private WebView webView;\n private TextView statusView;',
              ' private static final String GODBOT_URL="%s";\n private WebView webView;\n private TextView statusView;' % GIST, 1)
a = s.index(' private void loadEnabledScripts(WebView v){')
b = s.index('\n @Override public void onWindowFocusChanged', a)
s = s[:a] + new + s[b:]
p.write_text(s)
print('GodBot loader: interception mode, bootstrap %d chars' % len(js))
PY
