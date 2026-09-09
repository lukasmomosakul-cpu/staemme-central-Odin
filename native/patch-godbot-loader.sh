#!/usr/bin/env bash
set -euo pipefail

TARGET=$(find app/src/main -type f -name 'GameWebViewActivity.java' | head -n1)
test -n "$TARGET" && test -f "$TARGET"
test -s app/src/main/assets/odin-test.user.js

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
    BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("odin-test.user.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\n');r.close();
    String source=b.toString();
    android.util.Log.i("ODIN_TEST_USERSCRIPT","source_loaded bytes="+source.length()+" url="+path);
    String q=JSONObject.quote(source);
    runOnUiThread(()->{
     String runner="(function(){var CODE="+q+";try{var result=(0,window.eval)(CODE);console.log('ODIN_TEST_USERSCRIPT_EVAL_OK');return 'injected'}catch(e){console.error('ODIN_TEST_USERSCRIPT_EVAL_ERROR',e);return 'error:'+(e&&e.stack?e.stack:(e&&e.message?e.message:String(e)))}})()";
     v.evaluateJavascript(runner,value->android.util.Log.i("ODIN_TEST_USERSCRIPT","loader_result="+value+" url="+v.getUrl()));
    });
   }catch(Exception e){android.util.Log.e("ODIN_TEST_USERSCRIPT","asset_load_failed",e);}
  }).start();
 }
'''
s=s[:start]+new+s[end:]
p.write_text(s)
PY
