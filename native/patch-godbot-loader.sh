#!/usr/bin/env bash
set -euo pipefail
TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" || { echo 'GodBot loader: GameWebViewActivity.java not found'; exit 1; }
mkdir -p app/src/main/assets
URL='https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/'
echo "GodBot loader: downloading source"
curl -fsSL --retry 3 --connect-timeout 15 --max-time 60 "$URL" -o app/src/main/assets/godbot.user.js
test -s app/src/main/assets/godbot.user.js
VERSION=$(tr -d '[:space:]' < ../VERSION)
python3 - <<'PY'
from pathlib import Path
import re
p=Path('app/src/main/assets/godbot.user.js')
s=p.read_text()
s,n=re.subn(r"Object\.defineProperty\(window,\s*'[^']+',\s*\{ get:.*?\}\);",lambda m:'try{'+m.group(0)+'}catch(_odin_define){}',s)
p.write_text(s)
print(f'GodBot defineProperty bridges patched: {n}')
PY
rm -f app/src/main/assets/odin-test.user.js
python3 - "$TARGET" "$VERSION" <<'PY'
from pathlib import Path
import sys,json
p=Path(sys.argv[1]); version=sys.argv[2]; s=p.read_text()
a=s.index(' private void loadEnabledScripts(WebView v){')
b=s.index('\n @Override public void onBackPressed()',a)
ui="""(function(){try{var V='VERSION';function f(){var A=document.querySelectorAll('*');for(var i=0;i<A.length;i++){var e=A[i],t=(e.textContent||'').trim();if(/USERSCRIPT OK/i.test(t)&&e.children.length===0){e.remove();continue}if(t.indexOf('1.1.50')>=0&&e.children.length===0)e.textContent=t.replace(/1.1.50/g,V);if(/loader aktiv/i.test(t)){e.style.width='fit-content';e.style.maxWidth='calc(100% - 24px)';e.style.display='inline-flex';e.style.boxSizing='border-box';e.style.padding='6px 10px';e.style.margin='8px';e.style.borderRadius='8px';e.style.position='relative'}}}f();if(!window.__odinLoaderFix){window.__odinLoaderFix=1;new MutationObserver(f).observe(document.documentElement,{subtree:true,childList:true,characterData:true})}}catch(e){console.error('ODIN_LOADER_UI_FIX',e)}})();""".replace('VERSION',version)
qUi=json.dumps(ui)
new=f''' private void loadEnabledScripts(WebView v){{
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
  if(v.getTag(0x0D1A0001)!=null)return; v.setTag(0x0D1A0001,Boolean.TRUE);
  for(long d:new long[]{{2500L,5000L,9000L}})v.postDelayed(()->{{if(!isFinishing()&&webView==v)executeGodBotWhenReady(v);}},d);
 }}
 private void executeGodBotWhenReady(WebView v){{
  String u=v.getUrl()==null?"":v.getUrl(); if(!u.matches("(?i).*[/]game[.]php(?:[?].*)?$"))return;
  v.evaluateJavascript("(function(){{try{{return !!(document.body&&(window.game_data||window.TribalWars||document.querySelector('#content_value')))}}catch(e){{return false}}}})()",r->{{if("true".equals(r))injectGodBot(v);}});
 }}
 private void injectGodBot(WebView v){{
  try{{if(v.getTag(0x0D1A0002)!=null)return;v.setTag(0x0D1A0002,Boolean.TRUE);
   BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("godbot.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();String src=b.toString();
   java.util.regex.Matcher m=java.util.regex.Pattern.compile("(?m)^\\\\s*//\\\\s*@require\\\\s+([^\\\\s]+)").matcher(src);java.util.ArrayList<String> reqs=new java.util.ArrayList<>();while(m.find())reqs.add(m.group(1));
   final String qSrc=JSONObject.quote(src);
   final String shim=JSONObject.quote("(function(){{if(window.__odinGMShim)return;window.__odinGMShim=1;var p='odin_gm_';function g(k,d){{try{{var x=localStorage.getItem(p+k);return x===null?d:JSON.parse(x)}}catch(e){{return d}}}}function s(k,v){{try{{localStorage.setItem(p+k,JSON.stringify(v))}}catch(e){{}}}}window.unsafeWindow=window;window.GM_info=window.GM_info||{{script:{{name:'GodBot',version:'{version}'}}}};window.GM_getValue=window.GM_getValue||g;window.GM_setValue=window.GM_setValue||s;window.GM_deleteValue=window.GM_deleteValue||function(k){{try{{localStorage.removeItem(p+k)}}catch(e){{}}}};window.GM_listValues=window.GM_listValues||function(){{var a=[];try{{for(var i=0;i<localStorage.length;i++){{var k=localStorage.key(i);if(k&&k.indexOf(p)===0)a.push(k.slice(p.length))}}}}catch(e){{}}return a}};window.GM_addStyle=window.GM_addStyle||function(c){{var x=document.createElement('style');x.textContent=c;(document.head||document.documentElement).appendChild(x);return x}};window.GM_registerMenuCommand=window.GM_registerMenuCommand||function(){{}};window.GM_xmlhttpRequest=window.GM_xmlhttpRequest||function(o){{try{{var z={{status:200,responseText:OdinNative.httpGet(String(o.url)),response:''}};z.response=z.responseText;if(o.onload)o.onload(z);return z}}catch(e){{if(o.onerror)o.onerror({{status:0,error:e}});return{{abort:function(){{}}}}}}}};}})();");
   new Thread(()->{{try{{java.util.ArrayList<String>d=new java.util.ArrayList<>();for(String x:reqs)try{{d.add(new OdinNative().httpGet(x));}}catch(Exception ignored){{}}StringBuilder z=new StringBuilder("[");for(int i=0;i<d.size();i++){{if(i>0)z.append(',');z.append(JSONObject.quote(d.get(i)));}}z.append(']');final String qDeps=z.toString();runOnUiThread(()->{{String js="try{{new Function("+shim+")();var d="+qDeps+";for(var i=0;i<d.length;i++)try{{(0,eval)(d[i])}}catch(e){{console.error('ODIN_REQUIRE',e)}}(0,eval)("+qSrc+");"+{qUi}+"}}catch(e){{console.error('ODIN_GODBOT_EVAL_ERROR',e&&e.stack?e.stack:e)}}";v.evaluateJavascript(js,null);}});}}catch(Exception e){{android.util.Log.e("ODIN_GODBOT","dependency_failed",e);}}}}).start();
  }}catch(Exception e){{android.util.Log.e("ODIN_GODBOT","inject_failed",e);}}
 }}
'''
s=s[:a]+new+s[b:]
p.write_text(s)
PY
