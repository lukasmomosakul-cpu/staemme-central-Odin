#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET"
mkdir -p app/src/main/assets
URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$URL" -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
cp ../native/odin-test.user.js app/src/main/assets/odin-test.user.js
python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
a=s.index(' private void loadEnabledScripts(WebView v){')
b=s.index('\n @Override public void onBackPressed()',a)
new=r''' private void loadEnabledScripts(WebView v){
  String url=v.getUrl()==null?"":v.getUrl(); if(!url.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  try{
   String test="(function(){try{var e=document.getElementById('__odin_userscript_test');if(!e){e=document.createElement('div');e.id='__odin_userscript_test';e.style.cssText='position:fixed;top:55px;left:50%;transform:translateX(-50%);z-index:2147483647;background:#111;color:#0f0;padding:8px 14px;border:2px solid #0f0;border-radius:6px;font:bold 16px sans-serif;';(document.body||document.documentElement).appendChild(e)}e.textContent='USERSCRIPT OK';console.log('ODIN_TEST_USERSCRIPT_OK')}catch(x){console.error('ODIN_TEST_ERROR',x)}})()";
   v.evaluateJavascript(test,null);
   String status="(function(){try{var e=document.getElementById('__odin_loader_status');if(!e){e=document.createElement('div');e.id='__odin_loader_status';e.style.cssText='position:fixed;bottom:8px;left:8px;right:8px;z-index:2147483647;background:#111;color:#fff;padding:7px 9px;border:1px solid #777;border-radius:4px;font:12px sans-serif;opacity:.95;white-space:normal;word-break:break-word;max-height:30vh;overflow:auto';(document.body||document.documentElement).appendChild(e)}e.textContent='ODIN 1.1.44 · Loader aktiv'}catch(x){}})()";
   v.evaluateJavascript(status,null);
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js"))); StringBuilder bld=new StringBuilder(); String line; while((line=r.readLine())!=null)bld.append(line).append(System.lineSeparator()); r.close(); String src=bld.toString(); if(src.trim().isEmpty()) return;
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}function del(k){try{localStorage.removeItem(p+k)}catch(e){}}window.GM_getValue=window.GM_getValue||function(k,d){return g(k,d)};window.GM_setValue=window.GM_setValue||function(k,v){s(k,v)};window.GM_deleteValue=window.GM_deleteValue||function(k){del(k)};window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.substring(p.length))}}catch(e){}return a};window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){return 0};window.GM_unregisterMenuCommand=window.GM_unregisterMenuCommand||function(){};window.GM_openInTab=window.GM_openInTab||function(u){try{window.open(u,'_blank')}catch(e){location.href=u}};window.GM_notification=window.GM_notification||function(o){try{console.log(typeof o==='string'?o:(o&&o.text)||'')}catch(e){}};window.unsafeWindow=window.unsafeWindow||window;window.GM_info=window.GM_info||{script:{name:'GodBot',version:'525'},version:'525'};window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){var x={readyState:4,status:0,responseText:'',response:'',finalUrl:o.url,abort:function(){}};try{var body=OdinNative.httpGet(String(o.url));x.status=200;x.responseText=body;x.response=body;if(o.onload)o.onload(x)}catch(e){x.status=0;if(o.onerror)o.onerror(x)}return x};window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(GM_getValue(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){GM_setValue(k,v);return Promise.resolve()};window.GM.deleteValue=window.GM.deleteValue||function(k){GM_deleteValue(k);return Promise.resolve()};window.GM.listValues=window.GM.listValues||function(){return Promise.resolve(GM_listValues())};window.GM.addStyle=window.GM.addStyle||function(c){return Promise.resolve(GM_addStyle(c))};window.GM.registerMenuCommand=window.GM.registerMenuCommand||function(){return Promise.resolve(0)};window.GM.openInTab=window.GM.openInTab||function(u){return Promise.resolve(GM_openInTab(u))};window.GM.xmlHttpRequest=window.GM.xmlHttpRequest||function(o){return Promise.resolve(GM_xmlhttpRequest(o))};})();";
   String q=JSONObject.quote(shim+System.lineSeparator()+src);
   String js="try{new Function("+q+")();var e=document.getElementById('__odin_loader_status');if(e)e.textContent='ODIN 1.1.44 · GodBot eval OK';console.log('ODIN_GODBOT_EVAL_OK')}catch(e){var msg=e&&e.stack?e.stack:(e&&e.message?e.message:String(e));console.error('ODIN_GODBOT_EVAL_ERROR',msg);var x=document.getElementById('__odin_loader_status');if(x){x.innerHTML='ODIN 1.1.44 · GodBot FEHLER<br><pre id=\'__odin_error_text\' style=\'white-space:pre-wrap;user-select:text;color:#f55;margin:5px 0;font:12px monospace\'>ERROR</pre>';var z=document.getElementById('__odin_error_text');z.textContent=msg}}";
   v.evaluateJavascript(js,null);
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
 }
'''
s=s[:a]+new+s[b:]
needle='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}'
replacement='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)return "";BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}'
if needle not in s: raise SystemExit('OdinBridge pattern not found')
s=s.replace(needle,replacement); p.write_text(s)
PY
