#!/usr/bin/env bash
set -euo pipefail
# The workflow runs this script from the generated android/ directory.
# Keep generation inside that Capacitor project; never write to the repo-level app/ directory.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [ "$(basename "$PWD")" = "android" ]; then
  APP="$PWD/app"
else
  APP="$ROOT/android/app"
fi
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
JAVA_DIR="$APP/src/main/java/de/teamzentrale/odin"
mkdir -p "$JAVA_DIR" "$APP/src/main/assets" "$APP/src/main/res/values"

cat > "$APP/build.gradle" <<'EOF'
plugins { id 'com.android.application' }
android {
    namespace 'de.teamzentrale.odin'
    compileSdk 35
    defaultConfig {
        applicationId 'de.teamzentrale.odin'
        minSdk 26
        targetSdk 35
        versionCode 1
        versionName '1.0.0'
    }
    signingConfigs {
        odinRelease {
            storeFile file('odin-release.jks')
            storePassword System.getenv('ODIN_KEYSTORE_PASSWORD')
            keyAlias System.getenv('ODIN_KEY_ALIAS')
            keyPassword System.getenv('ODIN_KEY_PASSWORD')
        }
    }
    buildTypes {
        debug { signingConfig signingConfigs.odinRelease }
        release { signingConfig signingConfigs.odinRelease }
    }
}
dependencies { implementation 'androidx.core:core:1.13.1' }
EOF
python3 - "$APP/build.gradle" "$VERSION" <<'PY'
from pathlib import Path
import re,sys
p=Path(sys.argv[1]); v=sys.argv[2]; a=v.split('.'); code=int(a[0])*1000000+int(a[1])*1000+int(a[2])
s=p.read_text(); s=re.sub(r'\bversionCode\s+\d+',f'versionCode {code}',s,1); s=re.sub(r"versionName\s+['\"][^'\"]+['\"]",f"versionName '{v}'",s,1); p.write_text(s)
PY

cat > "$APP/src/main/AndroidManifest.xml" <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-sdk android:minSdkVersion="26" />
    <application android:theme="@style/AppTheme" android:label="Odin" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".GameWebViewActivity" android:exported="false" />
        <provider android:name="androidx.core.content.FileProvider"
            android:authorities="de.teamzentrale.odin.fileprovider"
            android:exported="false" android:grantUriPermissions="true">
            <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
EOF
mkdir -p "$APP/src/main/res/xml"
cat > "$APP/src/main/res/xml/file_paths.xml" <<'EOF'
<paths><cache-path name="apk" path="." /><external-cache-path name="apk_ext" path="." /></paths>
EOF
cat > "$APP/src/main/res/values/styles.xml" <<'EOF'
<resources><style name="AppTheme" parent="@android:style/Theme.Material.Light.NoActionBar"><item name="android:fontFamily">sans</item><item name="android:colorAccent">#333333</item><item name="android:windowFullscreen">true</item><item name="android:navigationBarColor">#ffffff</item><item name="android:statusBarColor">#ffffff</item><item name="android:windowLightStatusBar">true</item></style></resources>
EOF
cat > "$JAVA_DIR/MainActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.annotation.SuppressLint; import android.app.Activity; import android.content.Intent; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.util.Log; import android.webkit.JavascriptInterface; import java.net.HttpURLConnection;
public class MainActivity extends Activity {
 private WebView webView;
 private static final String ODIN_URL="https://staemme-central-odin.vercel.app/";
 @SuppressLint("SetJavaScriptEnabled") @Override protected void onCreate(Bundle b){
  super.onCreate(b); Fullscreen.apply(this);
  FrameLayout root=new FrameLayout(this); webView=new WebView(this);
  root.addView(webView,new FrameLayout.LayoutParams(-1,-1)); setContentView(root);
  WebSettings s=webView.getSettings();
  s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true); s.setDatabaseEnabled(true);
  s.setSupportMultipleWindows(true); s.setJavaScriptCanOpenWindowsAutomatically(true);
  // Ohne das zeigt die WebView nach einem Deploy weiter die alte Version an.
  s.setCacheMode(WebSettings.LOAD_NO_CACHE);
  CookieManager.getInstance().setAcceptCookie(true);
  CookieManager.getInstance().setAcceptThirdPartyCookies(webView,true);
  webView.setWebChromeClient(new WebChromeClient(){
   @Override public boolean onConsoleMessage(ConsoleMessage m){Log.d("ODIN_JS",m.message()+" @"+m.lineNumber());return true;}
  });
  webView.addJavascriptInterface(new OdinAppBridge(),"Android");
  webView.setWebViewClient(new WebViewClient(){
   @Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){
    String u=r.getUrl()==null?"":r.getUrl().toString();
    // Das Spiel gehoert in die eigene Activity, nicht in die Odin-Ansicht.
    if(u.contains("die-staemme.de")){openGameActivity("","","[]"); return true;}
    return false;
   }
  });
  webView.loadUrl(ODIN_URL);
 }
 private void openGameActivity(String accountId,String username,String accountsJson){
  Intent i=new Intent(this,GameWebViewActivity.class);
  i.putExtra("accountId",accountId); i.putExtra("username",username);
  i.putExtra("accountsJson",accountsJson==null?"[]":accountsJson);
  startActivity(i);
 }
 // Laedt die aktuelle APK und startet den System-Installer.
 private void downloadAndInstall(String url){
  new Thread(()->{
   try{
    java.io.File out=new java.io.File(getCacheDir(),"odin-latest.apk");
    HttpURLConnection c=(HttpURLConnection)new java.net.URL(url).openConnection();
    c.setInstanceFollowRedirects(true); c.setConnectTimeout(20000); c.setReadTimeout(120000);
    c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");
    java.io.InputStream in=c.getInputStream(); java.io.FileOutputStream fo=new java.io.FileOutputStream(out);
    byte[] buf=new byte[8192]; int n; while((n=in.read(buf))>0)fo.write(buf,0,n);
    fo.close(); in.close();
    android.net.Uri uri=androidx.core.content.FileProvider.getUriForFile(
      this,"de.teamzentrale.odin.fileprovider",out);
    Intent i=new Intent(Intent.ACTION_VIEW);
    i.setDataAndType(uri,"application/vnd.android.package-archive");
    i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION|Intent.FLAG_ACTIVITY_NEW_TASK);
    runOnUiThread(()->{try{startActivity(i);}catch(Exception e){Log.e("ODIN","installer",e);}});
   }catch(Exception e){
    Log.e("ODIN","apk download failed",e);
    // Rueckfall: Release-Seite oeffnen, damit der Nutzer nicht im Nichts steht.
    runOnUiThread(()->{try{startActivity(new Intent(Intent.ACTION_VIEW,android.net.Uri.parse(
      "https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest")));}catch(Exception ig){}});
   }
  }).start();
 }
 @Override public void onWindowFocusChanged(boolean f){super.onWindowFocusChanged(f);if(f)Fullscreen.apply(this);}
 @Override protected void onResume(){super.onResume();Fullscreen.apply(this);}
 @Override public void onBackPressed(){if(webView.canGoBack())webView.goBack();else super.onBackPressed();}
 private class OdinAppBridge{
  // Der Webcode ruft window.Android.* auf - diese Namen muessen exakt passen.
  @JavascriptInterface public void openGame(String accountId,String username,String password,String scriptsJson){
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,"[]"));
  }
  @JavascriptInterface public void openGameWithAccounts(String accountId,String username,String accountsJson){
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,accountsJson));
  }
  @JavascriptInterface public void updateApk(){
   downloadAndInstall("https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest/download/odin-latest.apk");
  }
 }
}
EOF
cat > "$JAVA_DIR/Fullscreen.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.Activity; import android.os.Build; import android.view.View; import android.view.WindowInsets; import android.view.WindowInsetsController; import android.view.WindowManager;
public final class Fullscreen {
 private Fullscreen(){}
 // Blendet Status- und Navigationsleiste aus; sie erscheinen kurz bei Wischen
 // vom Rand und verschwinden wieder von selbst.
 public static void apply(Activity a){
  try{
   a.getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,WindowManager.LayoutParams.FLAG_FULLSCREEN);
   if(Build.VERSION.SDK_INT>=30){
    // setDecorFitsSystemWindows(false) wurde entfernt: es legt den Inhalt UNTER
    // die Statusleiste, wodurch die Kopfleiste verdeckt wird sobald die Leiste
    // kurz wieder auftaucht.
    WindowInsetsController c=a.getWindow().getInsetsController();
    if(c!=null){c.hide(WindowInsets.Type.statusBars()|WindowInsets.Type.navigationBars());
     c.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);}
   }else{
    a.getWindow().getDecorView().setSystemUiVisibility(
      View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
      |View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY|View.SYSTEM_UI_FLAG_LAYOUT_STABLE
      |View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
   }
  }catch(Exception ignored){}
 }
}
EOF
cat > "$JAVA_DIR/OdinBubble.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import android.content.Intent; import android.graphics.Color;
import android.graphics.drawable.GradientDrawable; import android.os.Build; import android.provider.Settings;
import android.view.Gravity; import android.view.MotionEvent; import android.view.View; import android.view.WindowManager;
import android.widget.TextView;
// Frei bewegbares Overlay-Icon. Haengt am Application-Context, damit es die
// Activity ueberlebt; es verschwindet, wenn der Prozess endet.
public final class OdinBubble {
 private OdinBubble(){}
 private static View view; private static WindowManager wm;
 public static boolean allowed(Context c){ return Settings.canDrawOverlays(c); }
 public static void requestPermission(Context c){
  Intent i=new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
    android.net.Uri.parse("package:"+c.getPackageName()));
  i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK); c.startActivity(i);
 }
 public static synchronized void show(Context ctx){
  final Context app=ctx.getApplicationContext();
  if(view!=null||!allowed(app))return;
  wm=(WindowManager)app.getSystemService(Context.WINDOW_SERVICE);
  TextView b=new TextView(app); b.setText("O"); b.setTextColor(Color.WHITE);
  b.setTextSize(22f); b.setGravity(Gravity.CENTER);
  GradientDrawable g=new GradientDrawable(); g.setShape(GradientDrawable.OVAL);
  g.setColor(0xFF2B2B2B); g.setStroke(3,0xFFFFFFFF); b.setBackground(g);
  int type=Build.VERSION.SDK_INT>=26?WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                                    :WindowManager.LayoutParams.TYPE_PHONE;
  final WindowManager.LayoutParams lp=new WindowManager.LayoutParams(150,150,type,
    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, android.graphics.PixelFormat.TRANSLUCENT);
  lp.gravity=Gravity.TOP|Gravity.START; lp.x=24; lp.y=300;
  b.setOnTouchListener(new View.OnTouchListener(){
   float dx,dy,sx,sy; boolean moved;
   @Override public boolean onTouch(View v,MotionEvent e){
    switch(e.getAction()){
     case MotionEvent.ACTION_DOWN:
      dx=lp.x-e.getRawX(); dy=lp.y-e.getRawY(); sx=e.getRawX(); sy=e.getRawY(); moved=false; return true;
     case MotionEvent.ACTION_MOVE:
      lp.x=(int)(e.getRawX()+dx); lp.y=(int)(e.getRawY()+dy);
      if(Math.abs(e.getRawX()-sx)>12||Math.abs(e.getRawY()-sy)>12)moved=true;
      try{wm.updateViewLayout(v,lp);}catch(Exception ig){} return true;
     case MotionEvent.ACTION_UP:
      if(!moved){ // Tippen holt die App zurueck
       Intent i=new Intent(app,MainActivity.class);
       i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
       app.startActivity(i); hide();
      }
      return true;
    }
    return false;
   }
  });
  try{ wm.addView(b,lp); view=b; }catch(Exception e){ view=null; }
 }
 public static synchronized void hide(){
  try{ if(view!=null&&wm!=null)wm.removeView(view); }catch(Exception ignored){}
  view=null;
 }
}
EOF
cat > "$JAVA_DIR/GameWebViewActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.annotation.SuppressLint; import android.app.Activity; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.widget.LinearLayout; import android.widget.TextView; import android.widget.Button; import android.widget.HorizontalScrollView; import android.util.Log; import android.webkit.JavascriptInterface; import java.io.*; import java.net.*; import org.json.JSONObject;
public class GameWebViewActivity extends Activity {
 private WebView webView;
 private TextView statusView;
 // Zwischenspeicher fuer die vom Bootstrap angeforderten Skripte.
 private volatile String godbotSrc;
 private volatile java.util.List<String> godbotDeps=new java.util.ArrayList<>();
 void setStatus(String msg){runOnUiThread(()->{if(statusView!=null)statusView.setText("GodBot: "+msg);});android.util.Log.i("ODIN_GODBOT",msg);}
 @SuppressLint("SetJavaScriptEnabled") @Override protected void onCreate(Bundle b){super.onCreate(b); Fullscreen.apply(this);
  String activeName=getIntent().getStringExtra("username"); if(activeName==null||activeName.isEmpty())activeName=getIntent().getStringExtra("accountId"); if(activeName==null)activeName="";
  String accountsJson=getIntent().getStringExtra("accountsJson"); if(accountsJson==null)accountsJson="[]";
  LinearLayout root=new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setBackgroundColor(0xFFFFFFFF);
  root.addView(buildHeader(activeName),new LinearLayout.LayoutParams(-1,-2));
  webView=new WebView(this);
  root.addView(webView,new LinearLayout.LayoutParams(-1,0,1f));
  root.addView(buildFooter(accountsJson,activeName),new LinearLayout.LayoutParams(-1,-2));
  setContentView(root);WebSettings s=webView.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setDatabaseEnabled(true);android.webkit.CookieManager.getInstance().setAcceptCookie(true);android.webkit.CookieManager.getInstance().setAcceptThirdPartyCookies(webView,true);s.setSupportMultipleWindows(true);s.setJavaScriptCanOpenWindowsAutomatically(true);webView.setWebChromeClient(new WebChromeClient(){@Override public boolean onConsoleMessage(ConsoleMessage m){Log.d("ODIN_JS",m.message()+" @"+m.lineNumber()+" "+m.sourceId());return true;}
 // Ohne diese Rueckgabe verschluckt die WebView alert/confirm der Bestaetigungsseite.
 @Override public boolean onJsAlert(WebView v,String u,String msg,JsResult res){res.confirm();return true;}
 @Override public boolean onJsConfirm(WebView v,String u,String msg,JsResult res){res.confirm();return true;}
 @Override public boolean onShowFileChooser(WebView v,ValueCallback<android.net.Uri[]> cb,FileChooserParams p){cb.onReceiveValue(null);return true;}
 @Override public void onPermissionRequest(final PermissionRequest r){runOnUiThread(()->r.deny());}});webView.addJavascriptInterface(new OdinNative(),"OdinNative");webView.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return false;}
 @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest r){WebResourceResponse x=odinIntercept(r);return x!=null?x:super.shouldInterceptRequest(v,r);}
 @Override public void onPageFinished(WebView v,String u){injectManagedScripts(v);loadEnabledScripts(v);}});webView.loadUrl("https://www.die-staemme.de/");}
 private android.view.View buildHeader(String activeName){
  LinearLayout bar=new LinearLayout(this); bar.setOrientation(LinearLayout.HORIZONTAL);
  bar.setBackgroundColor(0xFF2B2B2B); bar.setPadding(24,18,12,18); bar.setGravity(android.view.Gravity.CENTER_VERTICAL);
  LinearLayout col=new LinearLayout(this); col.setOrientation(LinearLayout.VERTICAL);
  TextView t=new TextView(this); t.setText(activeName.isEmpty()?"Die Stämme":activeName);
  t.setTextColor(0xFFFFFFFF); t.setTextSize(16f); t.setSingleLine(true);
  col.addView(t);
  statusView=new TextView(this); statusView.setText("GodBot: wartet"); statusView.setTextColor(0xFFBBBBBB);
  statusView.setTextSize(11f); statusView.setSingleLine(true); col.addView(statusView);
  bar.addView(col,new LinearLayout.LayoutParams(0,-2,1f));
  Button back=new Button(this); back.setText("Odin"); back.setTextSize(12f); back.setAllCaps(false);
  back.setOnClickListener(x->finish());
  bar.addView(back,new LinearLayout.LayoutParams(-2,-2));
  Button min=new Button(this); min.setText("Minimieren"); min.setTextSize(12f); min.setAllCaps(false);
  min.setOnClickListener(x->{
   if(!OdinBubble.allowed(this)){
    setStatus("Bitte 'Über anderen Apps anzeigen' erlauben");
    OdinBubble.requestPermission(this); return;
   }
   OdinBubble.show(this);
   moveTaskToBack(true);
  });
  bar.addView(min,new LinearLayout.LayoutParams(-2,-2));
  return bar;
 }
 private android.view.View buildFooter(String accountsJson,String activeName){
  HorizontalScrollView sc=new HorizontalScrollView(this); sc.setBackgroundColor(0xFFF2F2F2);
  LinearLayout row=new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL); row.setPadding(12,10,12,10);
  try{
   org.json.JSONArray arr=new org.json.JSONArray(accountsJson);
   if(arr.length()==0){TextView e=new TextView(this);e.setText("Keine Accounts hinterlegt");e.setTextColor(0xFF777777);e.setTextSize(12f);e.setPadding(12,6,12,6);row.addView(e);}
   for(int i=0;i<arr.length();i++){
    org.json.JSONObject o=arr.optJSONObject(i); if(o==null)continue;
    String nm=o.optString("name",""); if(nm.isEmpty())continue;
    boolean active=nm.equals(activeName);
    TextView c=new TextView(this); c.setText(nm); c.setTextSize(12f); c.setPadding(22,10,22,10);
    c.setTextColor(active?0xFFFFFFFF:0xFF333333);
    android.graphics.drawable.GradientDrawable g=new android.graphics.drawable.GradientDrawable();
    g.setCornerRadius(18f); g.setColor(active?0xFF2B2B2B:0xFFFFFFFF); g.setStroke(1,0xFFCCCCCC);
    c.setBackground(g);
    LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-2,-2); lp.rightMargin=12; c.setLayoutParams(lp);
    row.addView(c);
   }
  }catch(Exception e){Log.e("ODIN","footer",e);}
  sc.addView(row); return sc;
 }
 private void injectManagedScripts(WebView v){try{BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("game-scripts.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\n');r.close();v.evaluateJavascript(b.toString(),null);}catch(Exception e){Log.e("ODIN","bootstrap",e);}}
 private void loadEnabledScripts(WebView v){ }
 private void executeGodBotWhenReady(WebView v){ }
 private void injectGodBot(WebView v){ }
 private WebResourceResponse odinIntercept(WebResourceRequest r){ return null; }
 @Override public void onWindowFocusChanged(boolean f){super.onWindowFocusChanged(f);if(f)Fullscreen.apply(this);}
 @Override protected void onResume(){super.onResume();Fullscreen.apply(this);OdinBubble.hide();}
 @Override public void onBackPressed(){if(webView.canGoBack())webView.goBack();else super.onBackPressed();}
 private void minimizeToApp(){finish();}
 private class OdinNative{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public void status(String m){setStatus(m==null?"":m);} @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setInstanceFollowRedirects(true);c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)throw new IOException("HTTP "+st);BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}
 private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}
}
EOF
printf '%s\n' "ODIN $VERSION · clean generator"
