#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET"
mkdir -p app/src/main/assets
URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$URL" -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
python3 - <<'PY'
from pathlib import Path
import re
p=Path('app/src/main/assets/godbot.user.js')
s=p.read_text()
pat=r"Object\\.defineProperty\\(window,\\s*'[^']+',\\s*\\{ get:.*?\\}\\);"
s,n=re.subn(pat, lambda m: 'try{' + m.group(0) + '}catch(_odin_define){}', s)
if n == 0:
    raise SystemExit('No GodBot Object.defineProperty bridge found')
p.write_text(s)
PY
cp ../native/odin-test.user.js app/src/main/assets/odin-test.user.js
python3 - "$TARGET" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
a=s.index(' private void loadEnabledScripts(WebView v){')
b=s.index('\n @Override public void onBackPressed()',a)
new=r''' private void loadEnabledScripts(WebView v){
  final String url=v.getUrl()==null?"":v.getUrl();
  if(!url.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  try{
   String boot="(function(){try{var e=document.getElementById('__odin_loader_status');if(!e){e=document.createElement('div');e.id='__odin_loader_status';e.style.cssText='position:fixed;bottom:8px;left:8px;right:8px;z-index:2147483647;background:#111;color:#fff;padding:7px 9px;border:1px solid #777;border-radius:4px;font:12px sans-serif;opacity:.95;white-space:pre-wrap;word-break:break-word;max-height:30vh;overflow:auto';(document.body||document.documentElement).appendChild(e)}e.textContent='ODIN 1.1.48 · Loader wartet auf Spielinitialisierung';}catch(x){}})()";
   v.evaluateJavascript(boot,null);
   if(v.getTag(0x0D1A0001)!=null) return;
   v.setTag(0x0D1A0001,Boolean.TRUE);
   final String[] delays={"3000","6000","10000"};
   for(final String delay:delays){
    v.postDelayed(()->{ if(!isFinishing() && webView==v) executeGodBotWhenReady(v); },Long.parseLong(delay));
   }
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","schedule_failed",e);}
 }
 private void executeGodBotWhenReady(WebView v){
  final String url=v.getUrl()==null?"":v.getUrl();
  if(!url.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  String ready="(function(){try{return !!(document.body && (window.game_data || window.TribalWars || document.querySelector('#content_value')))}catch(e){return false}})()";
  v.evaluateJavascript(ready,result->{
   if("true".equals(result)){ injectGodBot(v); }
   else { String wait="(function(){var e=document.getElementById('__odin_loader_status');if(e)e.textContent='ODIN 1.1.48 · Spiel noch nicht bereit – nächster Versuch folgt';})()"; v.evaluateJavascript(wait,null); }
  });
 }
 private void injectGodBot(WebView v){
  try{
   if(v.getTag(0x0D1A0002)!=null) return;
   v.setTag(0x0D1A0002,Boolean.TRUE);
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js"))); StringBuilder b=new StringBuilder(); String line; while((line=r.readLine())!=null)b.append(line).append('\\n'); r.close();
   String src=b.toString(); if(src.trim().isEmpty()) return;
   java.util.regex.Matcher m=java.util.regex.Pattern.compile("(?m)^\\s*//\\s*@require\\s+([^\\s]+)").matcher(src);
   final java.util.ArrayList<String> reqs=new java.util.ArrayList<>(); while(m.find()) reqs.add(m.group(1));
   final String qSrc=JSONObject.quote(src);
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}window.unsafeWindow=window;window.GM_info=window.GM_info||{script:{name:'GodBot',version:'Odin'}};window.GM_getValue=window.GM_getValue||g;window.GM_setValue=window.GM_setValue||s;window.GM_deleteValue=window.GM_deleteValue||function(k){try{localStorage.removeItem(p+k)}catch(e){}};window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}catch(e){}return a};window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){return 0};window.GM_notification=window.GM_notification||function(){};window.GM_openInTab=window.GM_openInTab||function(u){try{window.open(u,'_blank')}catch(e){}};window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){try{var body=OdinNative.httpGet(String(o.url));var z={status:200,responseText:body,response:body};if(o.onload)o.onload(z);return z}catch(e){if(o.onerror)o.onerror({status:0,error:e});return {abort:function(){}}}};window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(g(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){s(k,v);return Promise.resolve()};window.GM.deleteValue=window.GM.deleteValue||function(k){GM_deleteValue(k);return Promise.resolve()};window.GM.listValues=window.GM.listValues||function(){return Promise.resolve(GM_listValues())};window.GM.addStyle=window.GM.addStyle||function(c){return Promise.resolve(GM_addStyle(c))};})();";
   final String qShim=JSONObject.quote(shim);
   new Thread(()->{try{
    java.util.ArrayList<String> deps=new java.util.ArrayList<>();
    for(String req:reqs){try{deps.add(new OdinBridge().httpGet(req));}catch(Exception ignored){}}
    StringBuilder dq=new StringBuilder("["); for(int i=0;i<deps.size();i++){if(i>0)dq.append(',');dq.append(JSONObject.quote(deps.get(i)));} dq.append(']');
    final String qDeps=dq.toString();
    runOnUiThread(()->{String js="try{new Function("+qShim+")();var d="+qDeps+";for(var i=0;i<d.length;i++){try{(0,eval)(d[i])}catch(e){console.error('ODIN_GODBOT_REQUIRE_ERROR',e&&e.stack?e.stack:e)}}(0,eval)("+qSrc+");var e=document.getElementById('__odin_loader_status');if(e)e.textContent='ODIN 1.1.48 · GodBot eval OK';console.log('ODIN_GODBOT_EVAL_OK')}catch(e){var msg=e&&e.stack?e.stack:(e&&e.message?e.message:String(e));console.error('ODIN_GODBOT_EVAL_ERROR',msg);var x=document.getElementById('__odin_loader_status');if(x){x.textContent='ODIN 1.1.48 · GodBot FEHLER\\n'+msg;x.style.color='#f55'}}";v.evaluateJavascript(js,null);});
   }catch(Exception e){android.util.Log.e("ODIN_GODBOT","dependency_failed",e);}}).start();
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","inject_failed",e);}
 }
'''
s=s[:a]+new+s[b:]
needle='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}'
replacement='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)throw new IOException("HTTP "+st);BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}'
if needle not in s: raise SystemExit('OdinBridge pattern not found')
s=s.replace(needle,replacement)
p.write_text(s)
PY
