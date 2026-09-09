#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET"
mkdir -p app/src/main/assets
URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/GodBot.user.js'
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$URL" -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
python3 - app/src/main/assets/godbot.user.js "$TARGET" <<'PY'
from pathlib import Path
import re,sys
asset=Path(sys.argv[1]); p=Path(sys.argv[2]); s=p.read_text()
# Bundle @require dependencies at build time so WebView does not need Tampermonkey's loader.
src=asset.read_text()
requires=re.findall(r'^\s*//\s*@require\s+([^\s]+)',src,re.M)
if requires:
    import urllib.request
    parts=[]
    for u in requires:
        try:
            with urllib.request.urlopen(u,timeout=30) as r:
                parts.append(r.read().decode('utf-8'))
        except Exception as e:
            raise SystemExit(f'Failed to download @require {u}: {e}')
    asset.write_text('\n'.join(parts)+'\n'+src)

a=s.index(' private void loadEnabledScripts(WebView v){')
b=s.index('\n @Override public void onBackPressed()',a)
new=r''' private void loadEnabledScripts(WebView v){
  String url=v.getUrl()==null?"":v.getUrl();
  if(!url.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  try{
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));
   StringBuilder b=new StringBuilder(); String line;
   while((line=r.readLine())!=null)b.append(line).append(System.lineSeparator()); r.close();
   String src=b.toString(); if(src.trim().isEmpty()) return;
   String shim="(function(){if(window.__odinGMShim)return;window.__odinGMShim=true;var p='odin_gm_';function g(k,d){try{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}catch(e){return d}}function s(k,v){try{localStorage.setItem(p+k,JSON.stringify(v))}catch(e){}}function del(k){try{localStorage.removeItem(p+k)}catch(e){}}window.GM_getValue=window.GM_getValue||function(k,d){return g(k,d)};window.GM_setValue=window.GM_setValue||function(k,v){s(k,v)};window.GM_deleteValue=window.GM_deleteValue||function(k){del(k)};window.GM_listValues=window.GM_listValues||function(){var a=[];try{for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.substring(p.length))}}catch(e){}return a};window.GM_addStyle=window.GM_addStyle||function(c){var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){return 0};window.GM_unregisterMenuCommand=window.GM_unregisterMenuCommand||function(){};window.GM_openInTab=window.GM_openInTab||function(u){try{window.open(u,'_blank')}catch(e){location.href=u}};window.GM_notification=window.GM_notification||function(o){try{console.log(typeof o==='string'?o:(o&&o.text)||'')}catch(e){}};window.unsafeWindow=window.unsafeWindow||window;window.GM_info=window.GM_info||{script:{name:'GodBot',version:'525'},version:'525'};window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){var x={readyState:4,status:0,responseText:'',response:'',finalUrl:o.url,abort:function(){}};try{var body=OdinNative.httpGet(String(o.url));x.status=200;x.responseText=body;x.response=body;if(o.onload)o.onload(x)}catch(e){x.status=0;if(o.onerror)o.onerror(x)}return x};window.GM=window.GM||{};window.GM.getValue=window.GM.getValue||function(k,d){return Promise.resolve(GM_getValue(k,d))};window.GM.setValue=window.GM.setValue||function(k,v){GM_setValue(k,v);return Promise.resolve()};window.GM.deleteValue=window.GM.deleteValue||function(k){GM_deleteValue(k);return Promise.resolve()};window.GM.listValues=window.GM.listValues||function(){return Promise.resolve(GM_listValues())};window.GM.addStyle=window.GM.addStyle||function(c){return Promise.resolve(GM_addStyle(c))};window.GM.registerMenuCommand=window.GM.registerMenuCommand||function(){return Promise.resolve(0)};window.GM.openInTab=window.GM.openInTab||function(u){return Promise.resolve(GM_openInTab(u))};window.GM.xmlHttpRequest=window.GM.xmlHttpRequest||function(o){return Promise.resolve(GM_xmlhttpRequest(o))};})();";
   String q=JSONObject.quote(shim+System.lineSeparator()+src);
   String js="(function(){try{if(window.__odinGodBotLoaded)return;window.__odinGodBotLoaded=true;new Function("+q+")();console.log('ODIN_GODBOT_EVAL_OK')}catch(e){window.__odinGodBotLoaded=false;console.error('ODIN_GODBOT_EVAL_ERROR',e&&e.stack?e.stack:e)}})()";
   v.evaluateJavascript(js,null);
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","asset_load_failed",e);}
 }
'''
s=s[:a]+new+s[b:]
needle='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}'
replacement='private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)return "";BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}'
if needle not in s: raise SystemExit('OdinBridge pattern not found')
s=s.replace(needle,replacement)
p.write_text(s)
PY
