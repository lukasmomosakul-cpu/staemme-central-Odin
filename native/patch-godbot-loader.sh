#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
python3 - "$TARGET" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); s=p.read_text()
needle='if(sj!=null)try{JSONArray a=new JSONArray(sj);for(int i=0;i<a.length();i++){String src=a.getJSONObject(i).optString("source","");if(src.startsWith("https://"))managedScripts.add(src);}}catch(Exception ignored){}'
if needle not in s: raise SystemExit('GodBot insertion point not found')
s=s.replace(needle, needle+' managedScripts.add(GODBOT_URL);',1)
start=s.index(' private void loadEnabledScripts(WebView v){')
end=s.index('\n @Override public void onBackPressed()', start)
new=r''' private void loadEnabledScripts(WebView v){
  if(managedScripts.isEmpty())return;
  String path=v.getUrl()==null?"":v.getUrl();
  boolean inWorld=path.matches("(?i).*[/]game[.]php.*");
  if(!inWorld)return;
  for(String source:managedScripts){
   new Thread(()->{
    try{
     HttpURLConnection c=(HttpURLConnection)new URL(source).openConnection();
     c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Odin/1.x Tampermonkey-compatible loader");
     int st=c.getResponseCode();if(st<200||st>=300)return;
     BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream()));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();
     String script=b.toString();
     List<String> requires=new ArrayList<>();
     java.util.regex.Matcher m=java.util.regex.Pattern.compile("(?m)^\\s*//\\s*@require\\s+([^\\s]+)").matcher(script);
     while(m.find())requires.add(m.group(1));
     StringBuilder combined=new StringBuilder();
     for(String req:requires){try{HttpURLConnection rc=(HttpURLConnection)new URL(req).openConnection();rc.setConnectTimeout(15000);rc.setReadTimeout(30000);rc.setRequestProperty("User-Agent","Odin/1.x Tampermonkey-compatible loader");int rs=rc.getResponseCode();if(rs<200||rs>=300)continue;BufferedReader rr=new BufferedReader(new InputStreamReader(rc.getInputStream()));String x;while((x=rr.readLine())!=null)combined.append(x).append('\\n');rr.close();}catch(Exception ignored){}}
     combined.append('\\n').append(script);
     String q=JSONObject.quote(combined.toString());
     String key=JSONObject.quote(source);
     runOnUiThread(()->{
      String runner="(function(){var CODE="+q+",KEY="+key+";function install(w){try{if(!w||!w.document)return;if(!w.__odinUserscriptKeys)w.__odinUserscriptKeys={};if(w.__odinUserscriptKeys[KEY])return;w.__odinUserscriptKeys[KEY]=1;var store='odin-gm:'+KEY+':';w.GM_getValue=w.GM_getValue||function(k,d){try{var x=w.localStorage.getItem(store+k);return x===null?d:JSON.parse(x)}catch(e){return d}};w.GM_setValue=w.GM_setValue||function(k,val){try{w.localStorage.setItem(store+k,JSON.stringify(val))}catch(e){}};w.GM_deleteValue=w.GM_deleteValue||function(k){try{w.localStorage.removeItem(store+k)}catch(e){}};w.GM_listValues=w.GM_listValues||function(){var a=[];try{for(var i=0;i<w.localStorage.length;i++){var k=w.localStorage.key(i);if(k&&k.indexOf(store)===0)a.push(k.substring(store.length))}}catch(e){}return a};w.GM_addStyle=w.GM_addStyle||function(css){try{var s=w.document.createElement('style');s.textContent=css;w.document.documentElement.appendChild(s);return s}catch(e){return null}};w.GM_setClipboard=w.GM_setClipboard||function(x){try{if(w.navigator.clipboard&&w.navigator.clipboard.writeText)w.navigator.clipboard.writeText(String(x));}catch(e){}};w.GM_openInTab=w.GM_openInTab||function(u){try{return w.open(u,'_blank')}catch(e){return null}};w.GM_notification=w.GM_notification||function(x){try{if(w.console)w.console.log('Odin notification',x)}catch(e){}};w.GM_registerMenuCommand=w.GM_registerMenuCommand||function(){return null};w.GM_unregisterMenuCommand=w.GM_unregisterMenuCommand||function(){};w.GM_download=w.GM_download||function(u,n){try{var a=w.document.createElement('a');a.href=typeof u==='string'?u:(u&&u.url)||'';a.download=typeof n==='string'?n:(n&&n.name)||'';a.target='_blank';w.document.body.appendChild(a);a.click();a.remove()}catch(e){}};w.GM_info=w.GM_info||{script:{name:'GodBot',version:'Odin',namespace:'Odin'},scriptHandler:'Odin',version:'1'};w.unsafeWindow=w.unsafeWindow||w;try{w.eval(CODE)}catch(e){try{w.console&&w.console.error('Odin userscript error',e)}catch(_){}}}catch(e){}}install(w);try{for(var i=0;i<w.frames.length;i++)install(w.frames[i])}catch(e){}try{if(!w.__odinFramePump){w.__odinFramePump=setInterval(function(){install(w);try{for(var i=0;i<w.frames.length;i++)install(w.frames[i])}catch(e){}},1000);setTimeout(function(){try{clearInterval(w.__odinFramePump);delete w.__odinFramePump}catch(e){}},30000)}}catch(e){}}var w=window;install(w)})();";
      v.evaluateJavascript(runner,null);
     });
    }catch(Exception ignored){}
   }).start();
  }
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
