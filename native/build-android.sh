#!/usr/bin/env bash
set -euo pipefail

MAIN=$(find app/src/main -type f -name 'MainActivity.java' | head -n1)
test -n "$MAIN"
PKG=$(sed -n 's/^package[[:space:]]\+\(.*\);/\1/p' "$MAIN" | head -n1)
test -n "$PKG"
DIR=$(dirname "$MAIN")
mkdir -p "$DIR" app/src/main/assets app/src/main/res/xml
cp ../native/game-scripts.js app/src/main/assets/game-scripts.js

cat > app/src/main/res/xml/backup_rules.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content><include domain="sharedpref" path="odin_app_login.xml" /></full-backup-content>
EOF
cat > app/src/main/res/xml/data_extraction_rules.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules><cloud-backup><include domain="sharedpref" path="odin_app_login.xml" /></cloud-backup><device-transfer><include domain="sharedpref" path="odin_app_login.xml" /></device-transfer></data-extraction-rules>
EOF

cat > "$DIR/GameWebViewActivity.java" <<EOF
package $PKG;
import android.app.Activity; import android.content.Intent; import android.graphics.Color; import android.graphics.Typeface; import android.os.Bundle; import android.view.WindowManager; import android.view.Gravity; import android.webkit.*; import android.widget.*; import org.json.*; import java.io.*; import java.net.*; import java.util.*;
public class GameWebViewActivity extends Activity {
 private WebView webView; private String username="",password=""; private final List<String> managedScripts=new ArrayList<>();
 private int dp(int n){return (int)(n*getResources().getDisplayMetrics().density+0.5f);}
 @Override public void onCreate(Bundle state){super.onCreate(state);getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);getWindow().getDecorView().setSystemUiVisibility(android.view.View.SYSTEM_UI_FLAG_FULLSCREEN|android.view.View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY|android.view.View.SYSTEM_UI_FLAG_LAYOUT_STABLE|android.view.View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|android.view.View.SYSTEM_UI_FLAG_HIDE_NAVIGATION|android.view.View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);username=getIntent().getStringExtra("username");password=getIntent().getStringExtra("password");if(username==null)username="";if(password==null)password="";String sj=getIntent().getStringExtra("scriptsJson");if(sj!=null)try{JSONArray a=new JSONArray(sj);for(int i=0;i<a.length();i++){String src=a.getJSONObject(i).optString("source","");if(src.startsWith("https://"))managedScripts.add(src);}}catch(Exception ignored){}
  String savedGameUrl=getSharedPreferences("odin_game_state",MODE_PRIVATE).getString("lastGameUrl","");
  LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);
  LinearLayout toolbar=new LinearLayout(this);toolbar.setOrientation(LinearLayout.HORIZONTAL);toolbar.setGravity(Gravity.CENTER_VERTICAL);toolbar.setPadding(dp(16),0,dp(10),0);toolbar.setBackgroundColor(Color.rgb(15,20,35));
  TextView brand=new TextView(this);brand.setText("ODIN");brand.setTextColor(Color.WHITE);brand.setTextSize(15);brand.setTypeface(Typeface.DEFAULT,Typeface.BOLD);brand.setGravity(Gravity.CENTER_VERTICAL);
  TextView game=new TextView(this);game.setText("  •  Die Stämme");game.setTextColor(Color.rgb(185,190,205));game.setTextSize(14);game.setGravity(Gravity.CENTER_VERTICAL);
  Space spacer=new Space(this);toolbar.addView(brand,new LinearLayout.LayoutParams(-2,-1));toolbar.addView(game,new LinearLayout.LayoutParams(-2,-1));toolbar.addView(spacer,new LinearLayout.LayoutParams(0,-1,1));
  TextView minimize=new TextView(this);minimize.setText("⌄  Minimieren");minimize.setTextColor(Color.WHITE);minimize.setTextSize(14);minimize.setGravity(Gravity.CENTER);minimize.setPadding(dp(12),0,dp(12),0);minimize.setBackgroundColor(Color.rgb(28,35,54));minimize.setOnClickListener(v->minimizeToApp());toolbar.addView(minimize,new LinearLayout.LayoutParams(-2,dp(36)));toolbar.setOnClickListener(v->minimizeToApp());root.addView(toolbar,new LinearLayout.LayoutParams(-1,dp(48)));
  webView=new WebView(this);WebSettings ws=webView.getSettings();ws.setJavaScriptEnabled(true);ws.setDomStorageEnabled(true);ws.setDatabaseEnabled(true);ws.setSupportZoom(false);ws.setBuiltInZoomControls(false);ws.setDisplayZoomControls(false);ws.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);android.webkit.CookieManager cm=android.webkit.CookieManager.getInstance();cm.setAcceptCookie(true);cm.setAcceptThirdPartyCookies(webView,true);webView.setWebChromeClient(new WebChromeClient());webView.addJavascriptInterface(new OdinBridge(),"OdinNative");webView.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return false;}@Override public void onPageFinished(WebView v,String url){if(url!=null&&url.matches("(?i).*[/]game[.]php.*"))getSharedPreferences("odin_game_state",MODE_PRIVATE).edit().putString("lastGameUrl",url).apply();injectManagedScripts(v);prefillLogin(v);loadEnabledScripts(v);}});root.addView(webView,new LinearLayout.LayoutParams(-1,0,1));setContentView(root);if(savedGameUrl.matches("(?i).*[/]game[.]php.*"))webView.loadUrl(savedGameUrl);else webView.loadUrl("https://www.die-staemme.de/");}
 private void minimizeToApp(){String url=webView==null?"":webView.getUrl();android.content.SharedPreferences.Editor e=getSharedPreferences("odin_game_state",MODE_PRIVATE).edit().putBoolean("minimized",true);if(url!=null&&url.matches("(?i).*[/]game[.]php.*"))e.putString("lastGameUrl",url);e.apply();Intent i=new Intent(this,MainActivity.class);i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);startActivity(i);}
 private void injectManagedScripts(WebView v){try{BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("game-scripts.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();v.evaluateJavascript("(function(){"+b+"})()",null);}catch(Exception ignored){}}
 private void prefillLogin(WebView v){if(username.isEmpty()&&password.isEmpty())return;String u=JSONObject.quote(username),p=JSONObject.quote(password);String js="(function(){if(window.__odinPrefillStarted)return;window.__odinPrefillStarted=true;var U="+u+",P="+p+";function put(e,val){if(!e||e.value)return;try{var d=Object.getOwnPropertyDescriptor(HTMLInputElement.prototype,'value');if(d&&d.set)d.set.call(e,val);else e.value=val;}catch(x){e.value=val;}['input','change','blur'].forEach(function(n){e.dispatchEvent(new Event(n,{bubbles:true}));});}function f(){var a=document.querySelector('input[name=\"username\"],input[name=\"user\"],input[id=\"username\"],input[autocomplete=\"username\"],input[type=\"email\"],input[type=\"text\"]'),b=document.querySelector('input[type=\"password\"],input[name*=\"pass\" i],input[id*=\"pass\" i]');if(a&&U)put(a,U);if(b&&P)put(b,P);return !!(a&&b);}var n=0;function l(){if(f()||++n>=10)clearInterval(t);}var t=setInterval(l,200);f();setTimeout(function(){clearInterval(t);},2000);})();";v.evaluateJavascript(js,null);}
 private void loadEnabledScripts(WebView v){if(managedScripts.isEmpty())return;String path=v.getUrl()==null?"":v.getUrl();if(!path.matches("(?i).*[/]game[.]php.*"))return;for(String source:managedScripts)new Thread(()->{try{HttpURLConnection c=(HttpURLConnection)new URL(source).openConnection();c.setConnectTimeout(15000);c.setReadTimeout(30000);int st=c.getResponseCode();if(st<200||st>=300)return;BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream()));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\\n');r.close();String script=b.toString();List<String> requires=new ArrayList<>();java.util.regex.Matcher m=java.util.regex.Pattern.compile("(?m)^\\s*//\\s*@require\\s+([^\\s]+)").matcher(script);while(m.find())requires.add(m.group(1));StringBuilder combined=new StringBuilder();for(String req:requires){try{HttpURLConnection rc=(HttpURLConnection)new URL(req).openConnection();rc.setConnectTimeout(15000);rc.setReadTimeout(30000);int rs=rc.getResponseCode();if(rs<200||rs>=300)continue;BufferedReader rr=new BufferedReader(new InputStreamReader(rc.getInputStream()));String x;while((x=rr.readLine())!=null)combined.append(x).append('\\n');rr.close();}catch(Exception ignored){}}combined.append('\\n').append(script);String q=JSONObject.quote(combined.toString());runOnUiThread(()->v.evaluateJavascript("(function(){try{eval("+q+")}catch(e){console.error('Odin userscript error',e)}})()",null));}catch(Exception ignored){}}).start();}
 @Override public void onBackPressed(){if(webView!=null&&webView.canGoBack())webView.goBack();else minimizeToApp();}
 private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}
}
EOF

cat > "$MAIN" <<EOF
package $PKG;
import android.app.DownloadManager; import android.content.*; import android.net.Uri; import android.os.*; import android.provider.Settings; import android.webkit.*; import android.widget.Toast; import com.getcapacitor.BridgeActivity; import org.json.*;
public class MainActivity extends BridgeActivity{
 private static final String PREFS="odin_app_login",GAME_STATE="odin_game_state"; private long updateDownloadId=-1; private BroadcastReceiver updateReceiver;
 @Override public void onCreate(Bundle state){super.onCreate(state);WebView v=getBridge().getWebView();WebSettings s=v.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);android.webkit.CookieManager cm=android.webkit.CookieManager.getInstance();cm.setAcceptCookie(true);cm.setAcceptThirdPartyCookies(v,true);updateReceiver=new BroadcastReceiver(){@Override public void onReceive(Context c,Intent intent){if(!DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(intent.getAction()))return;long id=intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID,-1);if(id!=updateDownloadId)return;DownloadManager dm=(DownloadManager)getSystemService(Context.DOWNLOAD_SERVICE);if(dm==null)return;Uri apk=dm.getUriForDownloadedFile(id);if(apk==null){Toast.makeText(MainActivity.this,"Update-Download fehlgeschlagen",Toast.LENGTH_LONG).show();return;}try{Intent i=new Intent(Intent.ACTION_VIEW);i.setDataAndType(apk,"application/vnd.android.package-archive");i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_ACTIVITY_NEW_TASK);startActivity(i);}catch(Exception e){Toast.makeText(MainActivity.this,"Installer konnte nicht geöffnet werden: "+e.getClass().getSimpleName(),Toast.LENGTH_LONG).show();}}};if(Build.VERSION.SDK_INT>=33)registerReceiver(updateReceiver,new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE),Context.RECEIVER_EXPORTED);else registerReceiver(updateReceiver,new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE));v.addJavascriptInterface(new Object(){
  @JavascriptInterface public String getSavedAppLogin(){try{SharedPreferences p=getSharedPreferences(PREFS,MODE_PRIVATE);JSONObject o=new JSONObject();o.put("email",p.getString("email",""));o.put("password",p.getString("password",""));return o.toString();}catch(Exception e){return "";}}
  @JavascriptInterface public void saveAppLogin(String e,String p){getSharedPreferences(PREFS,MODE_PRIVATE).edit().putString("email",e==null?"":e).putString("password",p==null?"":p).apply();}
  @JavascriptInterface public void clearSavedAppLogin(){getSharedPreferences(PREFS,MODE_PRIVATE).edit().clear().apply();}
  @JavascriptInterface public void openGame(String accountId,String username,String password,String scriptsJson){getSharedPreferences(GAME_STATE,MODE_PRIVATE).edit().putBoolean("minimized",false).apply();Intent i=new Intent(MainActivity.this,GameWebViewActivity.class);i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);i.putExtra("accountId",accountId);i.putExtra("username",username==null?"":username);i.putExtra("password",password==null?"":password);i.putExtra("scriptsJson",scriptsJson==null?"[]":scriptsJson);startActivity(i);}
  @JavascriptInterface public void updateApk(){try{if(Build.VERSION.SDK_INT>=26&&!getPackageManager().canRequestPackageInstalls()){Toast.makeText(MainActivity.this,"Bitte Installation aus dieser Quelle erlauben",Toast.LENGTH_LONG).show();startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,Uri.parse("package:"+getPackageName())));return;}DownloadManager dm=(DownloadManager)getSystemService(Context.DOWNLOAD_SERVICE);if(dm==null){Toast.makeText(MainActivity.this,"Updater nicht verfügbar",Toast.LENGTH_LONG).show();return;}Uri uri=Uri.parse("https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest/download/odin-latest.apk?odin="+System.currentTimeMillis());DownloadManager.Request r=new DownloadManager.Request(uri);r.setTitle("Odin wird aktualisiert");r.setDescription("Neueste Version wird heruntergeladen");r.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);r.setMimeType("application/vnd.android.package-archive");r.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS,"odin-update.apk");updateDownloadId=dm.enqueue(r);Toast.makeText(MainActivity.this,"Update wird heruntergeladen",Toast.LENGTH_SHORT).show();}catch(Exception e){Toast.makeText(MainActivity.this,"Update fehlgeschlagen: "+e.getClass().getSimpleName(),Toast.LENGTH_LONG).show();}}
 },"Android");}
 @Override public void onDestroy(){if(updateReceiver!=null)try{unregisterReceiver(updateReceiver);}catch(Exception ignored){}super.onDestroy();}
}
EOF

python3 - <<'PY'
from pathlib import Path
import os,re
p=Path('app/src/main/AndroidManifest.xml');s=p.read_text()
if 'android.permission.REQUEST_INSTALL_PACKAGES' not in s:
    m=re.search(r'<manifest\b',s); assert m, 'manifest element missing'; e=s.find('>',m.start());s=s[:e+1]+'\n<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />'+s[e+1:]
if '<uses-sdk' in s:s=re.sub(r'<uses-sdk\b[^>]*/>','<uses-sdk android:minSdkVersion="26" />',s,count=1)
else:
    m=re.search(r'<manifest\b[^>]*>',s); assert m, 'manifest element missing'; s=s[:m.end()]+'\n<uses-sdk android:minSdkVersion="26" />'+s[m.end():]
if 'android:name=".GameWebViewActivity"' not in s:
    pos=s.rfind('</application>'); assert pos>=0, 'application element missing'; s=s[:pos]+'<activity android:name=".GameWebViewActivity" android:exported="false" />\n'+s[pos:]
p.write_text(s)
PY

python3 - <<'PY'
from pathlib import Path
import os,re
p=Path('app/build.gradle');s=p.read_text();v=os.environ.get('ODIN_VERSION','');a=v.split('.');code=int(a[0])*1000000+int(a[1])*1000+int(a[2]);s=re.sub(r'\bversionCode\s+\d+',f'versionCode {code}',s,count=1);s=re.sub(r'\bversionName\s+"[^"]+"',f'versionName "{v}"',s,count=1)
if re.search(r'\bminSdkVersion\s+\d+',s):s=re.sub(r'\bminSdkVersion\s+\d+','minSdkVersion 26',s,count=1)
elif re.search(r'\bminSdk\s+\d+',s):s=re.sub(r'\bminSdk\s+\d+','minSdk 26',s,count=1)
else:s=s.replace('defaultConfig {','defaultConfig {\n        minSdkVersion 26',1)
if 'odinRelease {' not in s:s=s.replace('android {','android {\n    signingConfigs { odinRelease { storeFile rootProject.file("odin-release.jks"); storePassword System.getenv("ODIN_KEYSTORE_PASSWORD"); keyAlias System.getenv("ODIN_KEY_ALIAS"); keyPassword System.getenv("ODIN_KEY_PASSWORD") } }',1)
if 'signingConfig signingConfigs.odinRelease' not in s:s=s.replace('buildTypes {','buildTypes {\n        debug { signingConfig signingConfigs.odinRelease }',1)
p.write_text(s)
PY
