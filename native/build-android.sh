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
dependencies {
    implementation 'androidx.core:core:1.13.1'
    // Multi-Profile: eigener Cookie- und Speicherbereich je Spielaccount.
    // Androids CookieManager ist sonst prozessweit, alle WebViews teilen sich
    // eine Sitzung - deshalb landete man immer beim zuletzt angemeldeten Konto.
    implementation 'androidx.webkit:webkit:1.12.1'
}
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
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-sdk android:minSdkVersion="26" />
    <application android:theme="@style/AppTheme" android:label="Odin" android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher_round">
        <!-- singleTask statt singleTop: singleTop verhindert nur eine zweite
             Instanz OBEN AUF DEMSELBEN Stapel. Startet das Symbol, eine
             Benachrichtigung oder die Spielansicht (documentLaunchMode legt
             eigene Aufgaben an) einen neuen Stapel, entsteht trotzdem eine
             zweite MainActivity - und damit eine zweite WebView mit derselben
             Supabase-Sitzung im selben localStorage. Die beiden ueberschreiben
             sich gegenseitig den Anmeldestatus. -->
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTask"
            android:configChanges="orientation|screenSize|keyboardHidden|screenLayout|uiMode"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".GameWebViewActivity" android:exported="false"
            android:documentLaunchMode="intoExisting" android:launchMode="singleTop"
            android:configChanges="orientation|screenSize|keyboardHidden|screenLayout|uiMode" />
        <activity android:name=".ParallelTestActivity" android:exported="false"
            android:configChanges="orientation|screenSize|keyboardHidden|screenLayout|uiMode" />
        <receiver android:name=".OdinAlarmReceiver" android:exported="false" />
        <receiver android:name=".OdinBootReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>
        <service android:name=".OdinJob" android:exported="false"
            android:permission="android.permission.BIND_JOB_SERVICE" />
        <service android:name=".OdinService" android:exported="false"
            android:foregroundServiceType="dataSync" />
        <provider android:name="androidx.core.content.FileProvider"
            android:authorities="de.teamzentrale.odin.fileprovider"
            android:exported="false" android:grantUriPermissions="true">
            <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths" />
        </provider>
    </application>
</manifest>
EOF
mkdir -p "$APP/src/main/res/xml" "$APP/src/main/res/drawable" "$APP/src/main/res/mipmap-anydpi-v26"
cat > "$APP/src/main/res/drawable/ic_odin_fg.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <!-- Zwei gekreuzte Schwerter: Klingen, Parierstangen, Knaeufe -->
    <path android:strokeColor="#F2F2F2" android:strokeWidth="7"
          android:strokeLineCap="round" android:pathData="M32,78 L74,36" />
    <path android:strokeColor="#F2F2F2" android:strokeWidth="7"
          android:strokeLineCap="round" android:pathData="M76,78 L34,36" />
    <path android:strokeColor="#C8962A" android:strokeWidth="6"
          android:strokeLineCap="round" android:pathData="M24,72 L40,88" />
    <path android:strokeColor="#C8962A" android:strokeWidth="6"
          android:strokeLineCap="round" android:pathData="M84,72 L68,88" />
    <path android:strokeColor="#C8962A" android:strokeWidth="9"
          android:strokeLineCap="round" android:pathData="M30,82 L29,83" />
    <path android:strokeColor="#C8962A" android:strokeWidth="9"
          android:strokeLineCap="round" android:pathData="M78,82 L79,83" />
</vector>
EOF
cat > "$APP/src/main/res/drawable/ic_odin_bg.xml" <<'EOF'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#2B2B2B" android:pathData="M0,0 H108 V108 H0 Z" />
</vector>
EOF
for N in ic_launcher ic_launcher_round; do
cat > "$APP/src/main/res/mipmap-anydpi-v26/$N.xml" <<'EOF'
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_odin_bg" />
    <foreground android:drawable="@drawable/ic_odin_fg" />
    <monochrome android:drawable="@drawable/ic_odin_fg" />
</adaptive-icon>
EOF
done
cat > "$APP/src/main/res/xml/file_paths.xml" <<'EOF'
<paths><cache-path name="apk" path="." /><external-cache-path name="apk_ext" path="." /></paths>
EOF
cat > "$APP/src/main/res/values/styles.xml" <<'EOF'
<resources><style name="AppTheme" parent="@android:style/Theme.Material.Light.NoActionBar"><item name="android:fontFamily">sans</item><item name="android:colorAccent">#333333</item><item name="android:windowFullscreen">true</item><item name="android:navigationBarColor">#ffffff</item><item name="android:statusBarColor">#ffffff</item><item name="android:windowLightStatusBar">true</item></style></resources>
EOF
cat > "$JAVA_DIR/MainActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.annotation.SuppressLint; import android.app.Activity; import android.content.Intent; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.util.Log; import android.webkit.JavascriptInterface; import java.net.HttpURLConnection; import android.os.Build;
public class MainActivity extends Activity {
 private WebView webView;
 private static final String ODIN_URL="https://staemme-central-odin.vercel.app/";
 private static final String PREFS="odin", LAST_URL="lastOdinUrl";
 static String SUPA_URL="",SUPA_KEY="",SUPA_TOKEN="",SUPA_TEAM="";
 // Guertel und Hosentraeger: singleTask sollte reichen, aber wenn Android
 // doch eine zweite Instanz anlegt, darf sie nicht mit derselben Sitzung
 // weiterarbeiten. Dieselbe Bauart wie der Riegel in GameWebViewActivity.
 private static MainActivity offen=null;
 private final String instanz=Integer.toHexString(System.identityHashCode(this));
 @SuppressLint("SetJavaScriptEnabled") @Override protected void onCreate(Bundle b){
  super.onCreate(b); Fullscreen.apply(this);
  MainActivity vorhanden=offen;
  if(vorhanden!=null&&vorhanden!=this&&!vorhanden.isFinishing()){
   OdinLog.schreib(this,"-","WICHTIG",
     "zweites Dashboard verworfen (bestehend #"+vorhanden.instanz+", neu #"+instanz+")");
   // Das bestehende nach vorn holen, damit der Benutzer nicht vor einem
   // leeren Bildschirm steht.
   try{
    Intent i=new Intent(this,MainActivity.class);
    i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
    startActivity(i);
   }catch(Exception ignored){}
   finish(); return;
  }
  offen=this;
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
  // Dort weitermachen, wo man war - nicht wieder auf der Anmeldeseite landen.
  String last=getSharedPreferences(PREFS,MODE_PRIVATE).getString(LAST_URL,ODIN_URL);
  if(last==null||!last.startsWith("https://staemme-central-odin"))last=ODIN_URL;
  if(last.contains("/login"))last=ODIN_URL;
  webView.loadUrl(last);
 }
 @Override protected void onPause(){
  super.onPause();
  try{ String u=webView.getUrl();
   if(u!=null&&!u.contains("/login"))
    getSharedPreferences(PREFS,MODE_PRIVATE).edit().putString(LAST_URL,u).apply();
  }catch(Exception ignored){}
 }
 private String gameWorld="";
 private void openGameActivity(String accountId,String username,String accountsJson){
  Intent i=new Intent(this,GameWebViewActivity.class);
  // Eigene Daten-URI je Account: Android fuehrt dadurch getrennte Aufgaben
  // und haelt mehrere Spielansichten gleichzeitig am Leben.
  if(accountId!=null&&!accountId.isEmpty())
   i.setData(android.net.Uri.parse("odin://account/"+accountId));
  i.putExtra("accountId",accountId); i.putExtra("username",username);
  i.putExtra("world",gameWorld==null?"":gameWorld);
  i.putExtra("accountsJson",accountsJson==null?"[]":accountsJson);
  i.putExtra("supaUrl",SUPA_URL); i.putExtra("supaKey",SUPA_KEY);
  i.putExtra("supaToken",SUPA_TOKEN); i.putExtra("supaTeam",SUPA_TEAM);
  OdinService.account=accountId;
  // Ohne dieses Flag entsteht bei jedem Klick eine NEUE Spielansicht: die
  // Sitzung startet von vorn und die Anmeldemaske erscheint wieder.
  i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
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
 // Gegenrichtung zu updateSupabaseTokens(): hat die App zwischendurch selbst
 // erneuert, dreht sich das Erneuerungstoken weiter und supabase-js im
 // Dashboard sitzt auf dem alten. Beim naechsten Auffrischen scheitert es
 // und meldet den Benutzer ab. Beim Zurueckkommen also das aktuelle Paar
 // hineinreichen - dann laufen beide Seiten auf derselben Kette.
 private void sitzungInsDashboard(){
  try{
   OdinService.ladeStatisch(this);
   if(webView==null||OdinService.token.isEmpty()||OdinService.refresh.isEmpty())return;
   final String js="if(window.odinSetSession)window.odinSetSession("
     +org.json.JSONObject.quote(OdinService.token)+","
     +org.json.JSONObject.quote(OdinService.refresh)+");";
   webView.post(()->{ try{ webView.evaluateJavascript(js,null); }catch(Exception ignored){} });
  }catch(Exception e){ android.util.Log.w("ODIN","sitzungInsDashboard",e); }
 }
 @Override protected void onDestroy(){
  if(offen==this)offen=null;
  super.onDestroy();
 }
 @Override protected void onResume(){
  // Kein sitzungInsDashboard() mehr: das Dashboard liest das Tokenpaar bei
  // jedem Zugriff selbst aus der App (lib/supabase.ts, Speicheradapter).
  super.onResume(); Fullscreen.apply(this);
  // Wer das Dashboard oeffnet, hat die Botschutz-Meldung gesehen - Vibration
  // und Wecker hoeren dann auf. Die Meldung selbst bleibt stehen.
  OdinService.botschutzGesehen();
 }
 @Override public void onBackPressed(){if(webView.canGoBack())webView.goBack();else super.onBackPressed();}
 private class OdinAppBridge{
  // Der Webcode ruft window.Android.* auf - diese Namen muessen exakt passen.
  @JavascriptInterface public void openGame(String accountId,String username,String password,String scriptsJson){
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,"[]"));
  }
  @JavascriptInterface public void openGameWithAccounts(String accountId,String username,String accountsJson){
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,accountsJson));
  }
  @JavascriptInterface public void openGameOnWorld(String accountId,String username,String accountsJson,String world){
   gameWorld=world==null?"":world.trim().toLowerCase();
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,accountsJson));
  }
  // Die Spielansicht hat keine eigene Supabase-Sitzung. Der Webcode reicht
  // Zugangstoken und Team hier durch, damit die Einstellungen abgeglichen
  // werden koennen.
  // supabase-js im Dashboard frischt seine Sitzung selbst auf und dreht
  // dabei das Erneuerungstoken weiter - das der App war danach verbrannt
  // und jede Erneuerung scheiterte. Deshalb reicht die Oberflaeche jedes
  // neue Paar sofort durch.
  // Gegenstueck zu updateSupabaseTokens: die Oberflaeche fragt das aktuelle
  // Paar ab, statt auf ein Nachreichen zu warten. Erkennt supabase-js an
  // dieser Methode, dass es in der App laeuft, schaltet es sein eigenes
  // Auffrischen ab - sonst erneuern beide und verbrennen sich gegenseitig
  // das Erneuerungstoken.
  @JavascriptInterface public String aktuelleSitzung(){
   try{
    OdinService.ladeStatisch(MainActivity.this);
    if(OdinService.token.isEmpty()||OdinService.refresh.isEmpty())return "";
    org.json.JSONObject o=new org.json.JSONObject();
    o.put("access_token",OdinService.token);
    o.put("refresh_token",OdinService.refresh);
    return o.toString();
   }catch(Exception e){ return ""; }
  }
  @JavascriptInterface public void updateSupabaseTokens(String accessToken,String refreshToken){
   if(accessToken==null||accessToken.isEmpty())return;
   SUPA_TOKEN=accessToken;
   OdinService.ladeStatisch(MainActivity.this);
   OdinService.token=accessToken;
   if(refreshToken!=null&&!refreshToken.isEmpty())OdinService.refresh=refreshToken;
   OdinService.sichern(MainActivity.this,OdinService.url,OdinService.key,
     accessToken,OdinService.team,OdinService.refresh);
   OdinService.sitzungFrisch();
   OdinService.erfolg();
  }
  // Testknopf aus den Einstellungen. Geht bewusst durch meldungAusSpiel(),
  // also durch genau dieselbe Auswertung wie eine echte Meldung aus der
  // Spielansicht - sonst wuerde der Test den Weg pruefen, den es gar nicht
  // gibt. Der Wortlaut ist GodBots eigener.
  // Fassung des eingebauten GodBot, fuer die Skriptseite im Dashboard.
  @JavascriptInterface public String godbotVersion(){
   try{ return OdinSkripte.versionAus(OdinSkripte.godbot(MainActivity.this)); }catch(Exception e){ return ""; }
  }
  // Testfassung: mehrere Welten gleichzeitig in einer Ansicht (Messung).
  // Zuweisung Konto -> Geraet (Dashboard, Einstellungen).
  @JavascriptInterface public String geraetId(){ return OdinService.geraetId(MainActivity.this); }
  @JavascriptInterface public String geraetName(){ return OdinService.geraetName(); }
  @JavascriptInterface public void kontoHierherHolen(String accountId){
   if(accountId==null||accountId.isEmpty())return;
   final android.content.Context app=getApplicationContext();
   new Thread(()->{
    Object[] e=OdinService.leaseHolen(app,accountId,true);
    if(e!=null&&(Boolean)e[0]){
     OdinService.WARTET.remove(accountId);
     GameWebViewActivity.neuLadenFuer(accountId,"Konto auf dieses Gerät geholt");
    }
   }).start();
  }
  @JavascriptInterface public void kontoFreigeben(String accountId){
   if(accountId==null||accountId.isEmpty())return;
   final android.content.Context app=getApplicationContext();
   new Thread(()->OdinService.leaseFreigeben(app,accountId)).start();
  }
  @JavascriptInterface public void parallelTest(String kontenJson){
   runOnUiThread(()->{
    Intent i=new Intent(MainActivity.this,ParallelTestActivity.class);
    i.putExtra("konten",kontenJson==null?"[]":kontenJson);
    startActivity(i);
   });
  }
  @JavascriptInterface public void testBotschutz(){
   try{ startForegroundService(new Intent(MainActivity.this,OdinService.class)); }catch(Exception ignored){}
   // Der Dienst braucht einen Moment, bis onCreate durch ist und lauf steht.
   new android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(()->{
    OdinService.meldungAusSpiel("🚨 Botschutz erkannt",
      "TEST aus den Einstellungen - Captcha-Sperre erkannt, GodBot pausiert. "
      +"Die Eskalation läuft wie im Ernstfall und endet, sobald du das "
      +"Dashboard oder die Spielansicht wieder öffnest.","alert");
    OdinLog.schreib(MainActivity.this,"-","WICHTIG","Botschutz-Test ausgeloest");
   },1500);
  }
  @JavascriptInterface public void setSupabaseSession(String url,String anonKey,String accessToken,String teamId){
   setSupabaseSession(url,anonKey,accessToken,teamId,"");
  }
  // Fuenftes Feld: das Erneuerungstoken. Ohne es endete die Sitzung nach
  // einer Stunde und die App konnte nichts mehr schreiben. Leer heisst
  // "behalte das gespeicherte" - eine aeltere Dashboard-Fassung soll das
  // vorhandene nicht loeschen.
  @JavascriptInterface public void setSupabaseSession(String url,String anonKey,String accessToken,String teamId,String refreshToken){
   SUPA_URL=url; SUPA_KEY=anonKey; SUPA_TOKEN=accessToken; SUPA_TEAM=teamId;
   OdinService.url=url; OdinService.key=anonKey; OdinService.token=accessToken;
   OdinService.ladeStatisch(MainActivity.this);
   if(refreshToken!=null&&!refreshToken.isEmpty())OdinService.refresh=refreshToken;
   OdinService.sichern(MainActivity.this,url,anonKey,accessToken,teamId,OdinService.refresh);
   OdinService.sitzungFrisch();
   OdinService.team=teamId; OdinService.device=android.os.Build.MODEL+"-"+
     android.provider.Settings.Secure.getString(getContentResolver(),
       android.provider.Settings.Secure.ANDROID_ID);
   runOnUiThread(()->{try{
    if(Build.VERSION.SDK_INT>=33&&checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)
        !=android.content.pm.PackageManager.PERMISSION_GRANTED)
     requestPermissions(new String[]{android.Manifest.permission.POST_NOTIFICATIONS},77);
    startForegroundService(new Intent(MainActivity.this,OdinService.class));
   }catch(Exception e){Log.e("ODIN","service",e);}});
  }
  // Zugangsdaten bleiben auf dem Geraet, verschluesselt im Android-Keystore.
  @JavascriptInterface public void setGameCredentials(String accountId,String benutzer,String passwort){
   if(accountId==null||accountId.isEmpty())return;
   if(passwort==null||passwort.isEmpty()){ OdinVault.loeschen(MainActivity.this,accountId); return; }
   OdinVault.speichern(MainActivity.this,accountId,benutzer==null?"":benutzer,passwort);
  }
  @JavascriptInterface public boolean hasGameCredentials(String accountId){
   return accountId!=null&&OdinVault.vorhanden(MainActivity.this,accountId);
  }
  @JavascriptInterface public String getGameUsername(String accountId){
   String[] d=accountId==null?null:OdinVault.lesen(MainActivity.this,accountId);
   return d==null?"":d[0];
  }
  @JavascriptInterface public void updateApk(){
   // Bewusst zusammengesetzt: der Build-Workflow ersetzt die zusammenhaengende
   // Zeichenkette durch die gerade gebaute Version, wodurch das Update stets
   // dieselbe Fassung nachgeladen haette.
   String base="https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/";
   downloadAndInstall(base+"latest"+"/download/"+"odin-latest"+".apk");
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
cat > "$JAVA_DIR/OdinService.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.*; import android.content.Context; import android.content.Intent;
import android.os.Build; import android.os.IBinder; import android.os.PowerManager;
import java.io.BufferedReader; import java.io.InputStreamReader; import java.net.HttpURLConnection; import java.net.URL;
import org.json.*;
// Haelt den Prozess am Leben und holt Benachrichtigungen anderer Geraete.
// Hinweis zur Grenze: der Dienst verhindert das Abraeumen des Prozesses und
// haelt die CPU wach. Android drosselt JS-Zeitgeber einer NICHT SICHTBAREN
// WebView trotzdem - vollstaendiger Hintergrundlauf ist damit nicht garantiert.
public class OdinService extends Service {
 public static final String CH_STATUS="odin_status", CH_ALERT="odin_alert";
 // Eigener Kanal fuer Wecker: hohe Wichtigkeit, damit der Full-Screen-Intent
 // greift, aber ohne Ton und Vibration - die App oeffnet sich ja selbst.
 // Eigene Kennung, weil Android bestehende Kanaele nicht nachtraeglich aendert.
 public static final String CH_WAKE="odin_wake_v2";
 static String url="",key="",token="",team="",device="",account="",refresh="";
 // Der Zugangstoken von Supabase gilt eine Stunde. Bisher kam er genau einmal
 // aus der Dashboard-Ansicht und wurde nie erneuert: nach einer Stunde lief
 // JEDER Schreibzugriff in HTTP 401 "JWT expired" - stundenlang, unbemerkt,
 // und damit auch die Botschutz-Meldung. Mit dem Erneuerungstoken holt sich
 // der Dienst selbst einen neuen.
 static volatile long letzteErneuerung=0L;
 static volatile int authFehler=0;
 // Jede geglueckte Anfrage beweist, dass der Token taugt. Ohne das blieb ein
 // einzelner Fehlschlag fuer immer stehen und die Warnung kam alle 30 Minuten
 // wieder, obwohl laengst alles lief.
 static volatile long letzterErfolg=0L;
 // Ein Erneuerungstoken ist bei Supabase einmal verwendbar. Ist es
 // verbraucht oder zurueckgezogen, antwortet der Server mit 400 - und daran
 // aendert kein weiterer Versuch etwas. Dann hilft nur eine frische Sitzung
 // aus dem Dashboard, und bis dahin wird nicht mehr gefragt.
 static volatile boolean authTot=false, totGemeldet=false;
 static void sitzungFrisch(){ authTot=false; totGemeldet=false; authFehler=0; }
 static void erfolg(){ authFehler=0; letzterErfolg=System.currentTimeMillis(); }
 // Laufende Dienstinstanz, damit die Spielansicht Meldungen oertlich
 // uebergeben kann statt ueber den Umweg Supabase.
 static volatile OdinService lauf=null;
 // --- Termine direkt aus GodBot (window.Odin.termin) ------------------------
 // Bisher kamen alle Termine auf dem Umweg GodBot -> localStorage -> Supabase
 // -> Dienst (alle 5 Minuten) an, und ein verpasster Termin wurde verworfen
 // ("if(weck<=jetzt)continue"). Am 23.09. fiel so der Raubzug um 03:00 aus
 // und kam bis 07:30 nicht wieder. Jetzt meldet GodBot jeden Planungszeit-
 // punkt sofort; der Dienst behaelt ihn, bis GodBot einen neuen meldet.
 // Schluessel: konto|skey -> {ms, konto, bez, art}
 static final java.util.concurrent.ConcurrentHashMap<String,Object[]> APP_TERMINE=new java.util.concurrent.ConcurrentHashMap<>();
 // Letztes Lebenszeichen von GodBot je Konto (window.Odin.lebt, alle 5 s).
 static final java.util.concurrent.ConcurrentHashMap<String,Long> LEBT=new java.util.concurrent.ConcurrentHashMap<>();
 static void lebt(String konto){ LEBT.put(konto==null?"":konto,System.currentTimeMillis()); }
 // Wann war die Spielansicht zuletzt im Vordergrund (= ungedrosselt)? Gesetzt
 // beim Kommen UND Gehen. War sie nach der Faelligkeit eines Termins vorn,
 // hatte GodBot seine Gelegenheit - dann hilft Nachwecken nicht. Am 24.09.
 // 13:31-13:42 wurde trotzdem sechsmal geweckt, obwohl jedes Weckfenster
 // 50 s lief.
 static final java.util.concurrent.ConcurrentHashMap<String,Long> VORN=new java.util.concurrent.ConcurrentHashMap<>();
 static void vorn(String konto){ VORN.put(konto==null?"":konto,System.currentTimeMillis()); }
 static long zuletztVorn(String konto){ Long l=VORN.get(konto==null?"":konto); return l==null?0L:l; }
 static long zuletztLebend(String konto){ Long l=LEBT.get(konto==null?"":konto); return l==null?0L:l; }
 // Zugangssperre (Captcha) je Konto: gesetzt, wenn die Spielansicht die
 // Sperrseite erkennt, geloescht, sobald GodBot wieder injiziert wird. Solange
 // sie steht, schweigt GodBot ABSICHTLICH - dann weder nachwecken noch die
 // Seite neu laden. Beides waere genau das Verhalten, das der Botschutz
 // bestraft.
 static final java.util.concurrent.ConcurrentHashMap<String,Long> SPERRE=new java.util.concurrent.ConcurrentHashMap<>();
 static void sperre(String konto,boolean an){ String k=konto==null?"":konto; if(an)SPERRE.putIfAbsent(k,System.currentTimeMillis()); else SPERRE.remove(k); }
 static boolean gesperrt(String konto){ return SPERRE.containsKey(konto==null?"":konto); }
 // --- Geraete-Sperre je Konto (Supabase: account_leases, 017) --------------
 // Laufen zwei Geraete fuer DASSELBE Konto mit GodBot, gehen doppelte
 // Anfragen an den Spielserver - Raubzug, Farmen, Rohstoffe zweimal. Genau
 // das bestraft der Botschutz. Deshalb darf GodBot je Konto nur auf dem
 // Geraet laufen, das die Sperre haelt. Gehalten wird sie, solange sich das
 // Geraet mindestens alle 3 Minuten meldet (leasePflegen, jede Minute).
 // Manuelles Spielen auf dem zweiten Geraet bleibt moeglich - nur GodBot
 // pausiert dort.
 private static String geraetIdCache=null;
 static String geraetId(Context c){
  if(geraetIdCache==null){
   String a="";
   try{ a=android.provider.Settings.Secure.getString(c.getContentResolver(),android.provider.Settings.Secure.ANDROID_ID); }catch(Exception ignored){}
   if(a==null||a.isEmpty()){
    android.content.SharedPreferences p=c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE);
    a=p.getString("geraet_id","");
    if(a.isEmpty()){ a=java.util.UUID.randomUUID().toString(); p.edit().putString("geraet_id",a).apply(); }
   }
   geraetIdCache="a-"+a;
  }
  return geraetIdCache;
 }
 static String geraetName(){ return (Build.MANUFACTURER+" "+Build.MODEL).trim(); }
 // konto -> {Boolean erhalten, String halterName, Long zeitpunkt}
 static final java.util.concurrent.ConcurrentHashMap<String,Object[]> LEASE=new java.util.concurrent.ConcurrentHashMap<>();
 // Konten, deren Ansicht auf die Sperre wartet (GodBot nicht geladen).
 static final java.util.Set<String> WARTET=java.util.concurrent.ConcurrentHashMap.newKeySet();
 private static String rpc(Context c,String fn,String body){
  ladeStatisch(c);
  if(url.isEmpty()||key.isEmpty())return null;
  for(int versuch=0;versuch<2;versuch++){
   try{
    HttpURLConnection con=(HttpURLConnection)new URL(url+"/rest/v1/rpc/"+fn).openConnection();
    con.setRequestMethod("POST"); con.setDoOutput(true);
    con.setConnectTimeout(10000); con.setReadTimeout(15000);
    con.setRequestProperty("apikey",key); con.setRequestProperty("Authorization","Bearer "+token);
    con.setRequestProperty("Content-Type","application/json");
    con.getOutputStream().write(body.getBytes("UTF-8"));
    int st=con.getResponseCode();
    if(st==401||st==403){ if(versuch==0&&erneuern(c,"rpc "+fn))continue; return null; }
    if(st>=400)return null;
    BufferedReader r=new BufferedReader(new InputStreamReader(con.getInputStream(),"UTF-8"));
    StringBuilder b=new StringBuilder(); String l; while((l=r.readLine())!=null)b.append(l); r.close();
    return b.toString();
   }catch(Exception e){ android.util.Log.w("ODIN_LEASE",fn,e); return null; }
  }
  return null;
 }
 // Nehmen oder verlaengern. null = Supabase nicht erreichbar.
 static Object[] leaseHolen(Context c,String konto,boolean erzwingen){
  if(konto==null||konto.isEmpty())return null;
  try{
   String body=new JSONObject().put("p_account",konto).put("p_geraet",geraetId(c))
     .put("p_name",geraetName()).put("p_erzwingen",erzwingen).toString();
   String r=rpc(c,"lease_holen",body);
   if(r==null)return null;
   JSONArray a=new JSONArray(r); if(a.length()==0)return null;
   JSONObject o=a.getJSONObject(0);
   Object[] e=new Object[]{o.optBoolean("erhalten",false),o.optString("geraet_name",""),System.currentTimeMillis()};
   Object[] alt=LEASE.put(konto,e);
   boolean jetzt=(Boolean)e[0], vorher=alt!=null&&(Boolean)alt[0];
   if(jetzt!=vorher||alt==null){
    String t=jetzt?(erzwingen?"Konto auf dieses Gerät geholt":"Konto diesem Gerät zugewiesen")
      :"Konto ist "+e[1]+" zugewiesen - GodBot und Anmeldung pausieren hier";
    OdinLog.schreib(c,"-",jetzt?"info":"WICHTIG",t+" ("+konto.substring(0,Math.min(8,konto.length()))+")");
   }
   return e;
  }catch(Exception ex){ return null; }
 }
 static void leaseFreigeben(Context c,String konto){
  Object[] e=LEASE.remove(konto==null?"":konto);
  if(e==null||!(Boolean)e[0])return;
  try{ rpc(c,"lease_freigeben",new JSONObject().put("p_account",konto).put("p_geraet",geraetId(c)).toString()); }
  catch(Exception ignored){}
 }
 // Darf GodBot fuer dieses Konto HIER laufen? Aus dem Zwischenspeicher,
 // wenn er jung genug ist, sonst fragen. Ist Supabase nicht erreichbar,
 // entscheidet der letzte Stand: ein fremder Halter, der sich vor weniger
 // als 3 Minuten gemeldet hat, sperrt weiter; sonst darf dieses Geraet
 // laufen - ein einzelnes Geraet soll nicht an einem Funkloch haengen.
 static boolean darfLaufen(Context c,String konto){
  long jetzt=System.currentTimeMillis();
  Object[] e=LEASE.get(konto==null?"":konto);
  if(e!=null&&(Boolean)e[0]&&jetzt-(Long)e[2]<60_000L)return true;
  Object[] neu=leaseHolen(c,konto,false);
  if(neu!=null)return (Boolean)neu[0];
  return !(e!=null&&!(Boolean)e[0]&&jetzt-(Long)e[2]<180_000L);
 }
 // Name des fremden Halters, falls ein anderes Geraet das Konto fuehrt.
 static String fremdHalter(String konto){
  Object[] e=LEASE.get(konto==null?"":konto);
  if(e==null||(Boolean)e[0])return null;
  if(System.currentTimeMillis()-(Long)e[2]>240_000L)return null;
  return (String)e[1];
 }
 private long letztePflege=0L;
 // Jede Minute: gehaltene Sperren verlaengern, wartende Ansichten erneut
 // versuchen lassen, Sperren geschlossener Ansichten freigeben.
 private void leasePflegen(){
  long jetzt=System.currentTimeMillis();
  if(jetzt-letztePflege<60_000L)return;
  letztePflege=jetzt;
  java.util.Set<String> offen=GameWebViewActivity.offeneKonten();
  for(String k:offen){
   Object[] e=LEASE.get(k);
   boolean hielt=e!=null&&(Boolean)e[0];
   if(hielt||WARTET.contains(k)){
    Object[] neu=leaseHolen(this,k,false);
    if(neu!=null&&(Boolean)neu[0]&&WARTET.remove(k))
     GameWebViewActivity.neuLadenFuer(k,"Geräte-Sperre frei - GodBot startet");
   }
  }
  for(String k:new java.util.ArrayList<>(LEASE.keySet())){
   Object[] e=LEASE.get(k);
   if(e!=null&&(Boolean)e[0]&&!offen.contains(k))leaseFreigeben(this,k);
  }
  // Fremde Sperren des Teams lesen (nur lesen, nichts nehmen). Damit weiss
  // der Wecker, dass er ein Konto, das ein anderes Geraet fuehrt, NICHT
  // wecken soll - sonst holten beide Geraete ihre Ansicht nach vorn.
  if(team.isEmpty())return;
  try{
   JSONArray a=new JSONArray(hole("account_leases?select=account_id,geraet_id,geraet_name,gemeldet&team_id=eq."
     +java.net.URLEncoder.encode(team,"UTF-8")));
   String ich=geraetId(this);
   for(int i=0;i<a.length();i++){
    JSONObject o=a.getJSONObject(i);
    String k=o.optString("account_id",""); if(k.isEmpty())continue;
    if(ich.equals(o.optString("geraet_id","")))continue;
    long gemeldet;
    try{ gemeldet=java.time.OffsetDateTime.parse(o.optString("gemeldet","")).toInstant().toEpochMilli(); }
    catch(Exception pe){ continue; }
    if(jetzt-gemeldet>180_000L)continue;
    Object[] mein=LEASE.get(k);
    if(mein!=null&&(Boolean)mein[0])continue;
    LEASE.put(k,new Object[]{false,o.optString("geraet_name",""),gemeldet});
   }
  }catch(Exception ex){ android.util.Log.w("ODIN_LEASE","lesen",ex); }
 }
 // Zeitstempel des letzten Laufs, keine Termine - GodBot bis v530 meldete
 // sie irrtuemlich (Nachwecken "Aufräumen ... überfällig", 23./24.09.).
 static boolean keinTermin(String skey){
  return skey!=null&&(skey.endsWith("|tw_am_check_at")||skey.endsWith("|tw_plan_aufraeumen_at")
    ||skey.equals("tw_am_check_at")||skey.equals("tw_plan_aufraeumen_at"));
 }
 static void appTermin(Context c,String konto,String bez,String skey,String art,long ms){
  if(keinTermin(skey))return;
  String kt=konto==null?"":konto;
  String k=kt+"|"+skey;
  Object[] alt=APP_TERMINE.get(k);
  if(alt!=null&&((Long)alt[0])==ms)return;
  if(ms<=0)APP_TERMINE.remove(k);
  else APP_TERMINE.put(k,new Object[]{ms,kt,bez==null?"":bez,art});
  appTermineSichern(c);
  OdinService s=lauf;
  if(s!=null)s.appTermineEinplanen(alt==null?0L:(Long)alt[0],kt,art);
 }
 private static void appTermineSichern(Context c){
  try{
   JSONObject o=new JSONObject();
   for(java.util.Map.Entry<String,Object[]> e:APP_TERMINE.entrySet()){
    Object[] t=e.getValue();
    o.put(e.getKey(),new JSONArray().put((long)(Long)t[0]).put((String)t[1]).put((String)t[2]).put((String)t[3]));
   }
   c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE).edit().putString("app_termine",o.toString()).apply();
  }catch(Exception ignored){}
 }
 private static void appTermineLaden(Context c){
  try{
   if(!APP_TERMINE.isEmpty())return;
   JSONObject o=new JSONObject(c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE).getString("app_termine","{}"));
   java.util.Iterator<String> it=o.keys();
   while(it.hasNext()){
    String k=it.next(); JSONArray a=o.optJSONArray(k); if(a==null||a.length()<4||keinTermin(k))continue;
    APP_TERMINE.put(k,new Object[]{a.optLong(0),a.optString(1),a.optString(2),a.optString(3)});
   }
  }catch(Exception ignored){}
 }
 // In die Weckliste uebernehmen. altMs: vorheriger Zeitpunkt desselben
 // Schluessels, dessen Eintrag hier entfernt wird.
 void appTermineEinplanen(long altMs,String altKonto,String altArt){
  long jetzt=System.currentTimeMillis();
  synchronized(faellig){
   if(altMs>0){
    String[] v=faellig.get(altMs-20_000L);
    if(v!=null&&v[0].equals(altKonto)&&v[2].equals(altArt))faellig.remove(altMs-20_000L);
   }
   for(Object[] t:APP_TERMINE.values()){
    long weck=((Long)t[0])-20_000L;
    if(weck>jetzt)faellig.put(weck,new String[]{(String)t[1],(String)t[2],(String)t[3]});
   }
  }
 }
 // Nachwecken: Ein Termin ist seit ueber 3 Minuten faellig, und GodBot hat
 // seitdem KEIN Lebenszeichen gegeben - er lief also nicht. Dann alle 5
 // Minuten erneut wecken, hoechstens eine Stunde lang. Laeuft GodBot, meldet
 // er von selbst einen neuen Zeitpunkt und der alte faellt weg.
 private final java.util.HashMap<String,Long> nachgeweckt=new java.util.HashMap<>();
 // Wie oft wurde fuer genau DIESEN Zeitpunkt schon nachgeweckt? Hoechstens
 // dreimal - hat GodBot den Termin dann nicht erneuert, hat das einen Grund
 // (Funktion aus, Truppen weg), und weiteres Wecken stoert nur.
 private final java.util.HashMap<String,long[]> nachweckZahl=new java.util.HashMap<>();
 private void ueberfaelligPruefen(){
  long jetzt=System.currentTimeMillis();
  for(java.util.Map.Entry<String,Object[]> e:APP_TERMINE.entrySet()){
   if(keinTermin(e.getKey())){ APP_TERMINE.remove(e.getKey()); continue; }
   Object[] t=e.getValue();
   long ms=(Long)t[0]; String konto=(String)t[1], bez=(String)t[2], art=(String)t[3];
   long ueber=jetzt-ms;
   if(ueber<180_000L||ueber>3_600_000L)continue;
   // Das Lebenszeichen taugt hier NICHT: GodBot tickt auch gedrosselt oder
   // schwebend weiter, erledigt den Termin dann aber nicht (23.09. 20:00 und
   // 21:05). Massgeblich ist, ob die Ansicht gerade ungedrosselt laeuft.
   if(GameWebViewActivity.laeuftUngedrosselt(this,konto))continue;
   if(zuletztVorn(konto)>ms+60_000L)continue;
   if(gesperrt(konto))continue;
   Long z=nachgeweckt.get(e.getKey());
   if(z!=null&&jetzt-z<300_000L)continue;
   long[] zahl=nachweckZahl.get(e.getKey());
   if(zahl==null||zahl[0]!=ms){ zahl=new long[]{ms,0}; nachweckZahl.put(e.getKey(),zahl); }
   if(zahl[1]>=3)continue;
   zahl[1]++;
   nachgeweckt.put(e.getKey(),jetzt);
   String text=art+" seit "+(ueber/60000)+" Min überfällig und nicht erneuert - wecke erneut ("+zahl[1]+"/3)";
   OdinLog.schreib(this,"-","WICHTIG",text);
   protokoll(this,"WICHTIG","wecker",text);
   wecken(this,konto,bez,art,"Raubzug".equals(art));
  }
 }
 private PowerManager.WakeLock lock;
 private Thread poller; private volatile boolean running;
 private String lastSeen="";
 @Override public IBinder onBind(Intent i){ return null; }
 // Ohne dauerhafte Ablage stehen die Zugangsdaten nur in statischen Feldern:
 // nach einem Neustart oder wenn Android die App abraeumt, waeren sie weg und
 // es wuerden keine Wecker mehr gesetzt.
 public static void sichern(Context c,String u,String k,String t,String tm){ sichern(c,u,k,t,tm,refresh); }
 public static void sichern(Context c,String u,String k,String t,String tm,String rf){
  refresh=rf==null?"":rf;
  c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE).edit()
   .putString("url",u).putString("key",k).putString("token",t).putString("team",tm)
   .putString("refresh",refresh).apply();
 }
 // Neuen Zugangstoken holen. true, wenn danach ein frischer Token vorliegt.
 // Hoechstens alle 20 s, damit ein dauerhaft ungueltiges Erneuerungstoken
 // keine Schleife ausloest - jeder Aufrufer versucht es genau einmal neu.
 static boolean erneuern(Context c){ return erneuern(c,"?"); }
 // Der Anlass steht jetzt mit im Protokoll. "Zugangstoken erneuert" allein
 // sagte nicht, welcher Weg gefragt hat - und damit auch nicht, wer die
 // zusaetzlichen Erneuerungen ausloest.
 static synchronized boolean erneuern(Context c,String anlass){
  try{
   if(authTot)return false;
   ladeStatisch(c);
   if(url.isEmpty()||key.isEmpty()||refresh.isEmpty())return false;
   long jetzt=System.currentTimeMillis();
   if(jetzt-letzteErneuerung<20_000L)return false;
   letzteErneuerung=jetzt;
   HttpURLConnection x=(HttpURLConnection)new URL(url+"/auth/v1/token?grant_type=refresh_token").openConnection();
   x.setRequestMethod("POST"); x.setRequestProperty("apikey",key);
   x.setRequestProperty("Content-Type","application/json");
   x.setConnectTimeout(15000); x.setReadTimeout(20000); x.setDoOutput(true);
   JSONObject rumpf=new JSONObject(); rumpf.put("refresh_token",refresh);
   java.io.OutputStream os=x.getOutputStream();
   os.write(rumpf.toString().getBytes("UTF-8")); os.close();
   int st=x.getResponseCode();
   java.io.InputStream in=(st>=200&&st<400)?x.getInputStream():x.getErrorStream();
   StringBuilder b=new StringBuilder();
   if(in!=null){ BufferedReader r=new BufferedReader(new InputStreamReader(in,"UTF-8"));
    String l; while((l=r.readLine())!=null)b.append(l); r.close(); }
   if(st<200||st>=400){
    authFehler++;
    android.util.Log.w("ODIN_SVC","erneuern HTTP "+st+" "+b);
    if(st==400||st==401){
     // Endgueltig. Das tote Token wegwerfen, sonst versucht es der Dienst
     // alle 30 Sekunden weiter und schreibt das Protokoll voll - genau das
     // ist am 19.09. ueber eine Stunde lang passiert.
     refresh=""; authTot=true;
     sichern(c,url,key,token,team,"");
     if(!totGemeldet){
      totGemeldet=true;
      OdinLog.schreib(c,"-","FEHLER","Erneuerungstoken verbraucht (HTTP "+st+") - Dashboard öffnen");
     }
    }else OdinLog.schreib(c,"-","FEHLER","Token-Erneuerung fehlgeschlagen: HTTP "+st);
    return false;
   }
   JSONObject o=new JSONObject(b.toString());
   String neu=o.optString("access_token","");
   if(neu.isEmpty()){ authFehler++; return false; }
   token=neu;
   String nrf=o.optString("refresh_token","");
   if(!nrf.isEmpty())refresh=nrf;
   sichern(c,url,key,token,team,refresh);
   sitzungFrisch();
   OdinLog.schreib(c,"-","info","Zugangstoken erneuert (Anlass: "+anlass+")");
   return true;
  }catch(Exception e){
   authFehler++;
   android.util.Log.w("ODIN_SVC","erneuern",e);
   return false;
  }
 }
 // Nach dem Abraeumen der App ist der Prozess weg und die statischen Felder
 // sind leer. Der Wecker-Empfaenger laeuft dann in einem frischen Prozess -
 // ohne Nachladen koennte er weder melden noch abgleichen.
 static void ladeStatisch(Context c){
  android.content.SharedPreferences p=c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE);
  if(url.isEmpty())url=p.getString("url","");
  if(key.isEmpty())key=p.getString("key","");
  if(token.isEmpty())token=p.getString("token","");
  if(team.isEmpty())team=p.getString("team","");
  if(refresh.isEmpty())refresh=p.getString("refresh","");
  if(device.isEmpty())device=Build.MODEL;
 }
 private void laden(){
  ladeStatisch(this);
  android.content.SharedPreferences p=getSharedPreferences("odin_svc",Context.MODE_PRIVATE);
  if(url.isEmpty())url=p.getString("url","");
  if(key.isEmpty())key=p.getString("key","");
  if(token.isEmpty())token=p.getString("token","");
  if(team.isEmpty())team=p.getString("team","");
  if(refresh.isEmpty())refresh=p.getString("refresh","");
  if(device.isEmpty())device=Build.MODEL+"-"+android.provider.Settings.Secure.getString(
    getContentResolver(),android.provider.Settings.Secure.ANDROID_ID);
 }
 @Override public int onStartCommand(Intent i,int flags,int startId){
  laden(); return START_STICKY;   // nach dem Abraeumen wieder anlaufen
 }
 @Override public void onCreate(){
  super.onCreate(); laden(); channels();
  Notification n=new Notification.Builder(this,CH_STATUS)
    .setContentTitle("Odin läuft").setContentText("Benachrichtigungen aktiv")
    .setSmallIcon(android.R.drawable.ic_dialog_info).setOngoing(true).build();
  if(Build.VERSION.SDK_INT>=29)
    startForeground(1,n,android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC);
  else startForeground(1,n);
  try{ PowerManager pm=(PowerManager)getSystemService(Context.POWER_SERVICE);
   lock=pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,"odin:bot"); lock.acquire(); }catch(Exception ignored){}
  OdinAlarm.wachhund(this);   // Rueckfall, feuert auf manchen Geraeten nie
  OdinJob.planen(this);       // eigentlicher Wiederbeleber
  lauf=this;
  appTermineLaden(this); appTermineEinplanen(0L,"","");
  running=true; poller=new Thread(this::loop); poller.start();
 }
 // Meldungen aus der Spielansicht liefen bisher AUSSCHLIESSLICH ueber
 // Supabase: GodBot schreibt eine Zeile, der Dienst holt sie zurueck. Zwei
 // Haken - ohne Netz oder mit abgelaufenem Token kommt nichts an, und poll()
 // ueberspringt Zeilen vom eigenen Geraet ohnehin. Der Botschutz-Wecker
 // konnte so nie anspringen. Jetzt geht die Meldung direkt in dieselbe
 // Auswertung; der Weg ueber Supabase bleibt fuer die anderen Geraete.
 public static void meldungAusSpiel(String titel,String text,String stufe){
  OdinService s=lauf; if(s==null)return;
  try{ s.ausSpiel(titel==null?"":titel,text==null?"":text); }
  catch(Exception e){ android.util.Log.w("ODIN_SVC","meldungAusSpiel",e); }
 }
 // NICHT show(): das wuerde fuer jede Meldung eine Benachrichtigung bauen.
 // Meldungen vom eigenen Geraet hat poll() immer verworfen, GodBot zeigt
 // seinen Farmwert und die Statistiken ja selbst an. Oertlich zugestellt
 // wird nur, was einen Wecker oder eine Buendelung ausloest.
 private void ausSpiel(String titel,String text){
  String zusammen=titel+" "+text;
  if(IST_BOTSCHUTZ.matcher(zusammen).find()&&IST_ENTWARNUNG.matcher(zusammen).find()){
   botschutzBeenden("Entwarnung von GodBot"); return;
  }
  if(nbBotschutzAn&&IST_BOTSCHUTZ.matcher(zusammen).find()){ botschutzStarten(titel); return; }
  if(nbAngriffeGebuendelt&&IST_ANGRIFF.matcher(zusammen).find())angriffSammeln(titel,text);
 }
 private void channels(){
  NotificationManager nm=getSystemService(NotificationManager.class);
  nm.createNotificationChannel(new NotificationChannel(CH_STATUS,"Odin Status",NotificationManager.IMPORTANCE_LOW));
  NotificationChannel a=new NotificationChannel(CH_ALERT,"Odin Meldungen",NotificationManager.IMPORTANCE_HIGH);
  a.enableVibration(true); nm.createNotificationChannel(a);
  NotificationChannel wk=new NotificationChannel(CH_WAKE,"Odin Termine",NotificationManager.IMPORTANCE_HIGH);
  wk.enableVibration(false); wk.setVibrationPattern(null); wk.setSound(null,null);
  wk.setShowBadge(false); nm.createNotificationChannel(wk);
 }
 // Feste Nummern, damit eine Meldung die vorige ERSETZT statt sich daneben
 // zu legen. Genau daran lag die Flut einzelner Angriffsmeldungen.
 private static final int ID_ANGRIFFE=4801, ID_VORWARNUNG=4802, ID_BOTSCHUTZ=4803, ID_AUTH=4804;
 // Fuenf Stunden lief der Dienst mit abgelaufenem Token, ohne dass es
 // irgendwo sichtbar wurde - nur Logzeilen, die niemand nachts liest.
 // Bleibt die Erneuerung haengen, gehoert das ins Meldungsfeld.
 private long authGemeldet=0L;
 private void authPruefen(){
  long jetzt=System.currentTimeMillis();
  if(!authTot&&authFehler<3){
   if(authGemeldet>0){
    authGemeldet=0;
    try{ getSystemService(NotificationManager.class).cancel(ID_AUTH); }catch(Exception ignored){}
   }
   return;
  }
  // Entscheidend ist nicht die Fehlerzahl, sondern ob seit einer Weile
  // ueberhaupt etwas durchgeht. Sonst nervt die Meldung im laufenden Betrieb.
  if(!authTot&&(letzterErfolg==0L||jetzt-letzterErfolg<20*60*1000L))return;
  if(jetzt-authGemeldet<30*60*1000L)return;
  authGemeldet=jetzt;
  zeigeFest(ID_AUTH,CH_ALERT,"Odin: Anmeldung abgelaufen",
    "Der Zugang zu Supabase lässt sich nicht erneuern - Einstellungen und Meldungen "
    +"werden nicht mehr geschrieben. Bitte das Dashboard einmal öffnen.",true);
  OdinLog.schreib(this,"-","FEHLER","Zugangstoken kann nicht erneuert werden");
 }
 // Vorwarnung: ein Termin steht an, aber nichts laeuft ungedrosselt. Ohne
 // Hinweis merkt man erst hinterher, dass der Raubzug ausgefallen ist.
 private long vorgewarntFuer=0L;
 private void vorwarnPruefen(){
  if(!nbVorwarnAn)return;
  java.util.Map.Entry<Long,String[]> e;
  synchronized(faellig){ e=faellig.firstEntry(); }
  if(e==null)return;
  long ziel=e.getKey(), jetzt=System.currentTimeMillis();
  long rest=ziel-jetzt;
  if(rest<=0||rest>nbVorwarnMin*60_000L)return;
  if(ziel==vorgewarntFuer)return;
  String konto=e.getValue()[0], art=e.getValue()[2];
  // Laeuft die Seite ungedrosselt, erledigt GodBot den Termin selbst.
  if(GameWebViewActivity.laeuftUngedrosselt(this,konto))return;
  vorgewarntFuer=ziel;
  String text=art+" in "+Math.max(1,Math.round(rest/60000f))+" Min – Odin läuft gerade nicht";
  OdinLog.schreib(this,"-","WICHTIG","Vorwarnung: "+text);
  protokoll(this,"WICHTIG","wecker","Vorwarnung: "+text);
  zeigeFest(ID_VORWARNUNG,CH_ALERT,"Termin steht an",text,false);
 }
 // Botschutz: erst in Abstaenden vibrieren, nach einer Weile der Wecker. Er
 // hoert auf, sobald die App im Vordergrund ist - dann hast du es gesehen.
 private volatile long botschutzSeit=0L, botschutzLetzteVib=0L;
 private volatile String botschutzText="";
 private android.media.Ringtone botschutzKlang=null;
 void botschutzStarten(String text){
  if(!nbBotschutzAn)return;
  if(botschutzSeit>0)return;              // laeuft schon
  botschutzSeit=System.currentTimeMillis();
  botschutzLetzteVib=0L; botschutzText=text;
  OdinLog.schreib(this,"-","WICHTIG","Botschutz-Eskalation gestartet");
  protokoll(this,"WICHTIG","botschutz","Eskalation gestartet: "+text);
 }
 // Von aussen quittierbar, ohne Verweis auf den laufenden Dienst: das
 // Dashboard ruft es im onResume, der Dienst prueft es im Takt.
 static volatile long botschutzGesehenAm=0L;
 public static void botschutzGesehen(){ botschutzGesehenAm=System.currentTimeMillis(); }
 void botschutzBeenden(String grund){
  if(botschutzSeit==0)return;
  botschutzSeit=0L;
  try{ if(botschutzKlang!=null&&botschutzKlang.isPlaying())botschutzKlang.stop(); }catch(Exception ignored){}
  botschutzKlang=null;
  try{ getSystemService(NotificationManager.class).cancel(ID_BOTSCHUTZ); }catch(Exception ignored){}
  OdinLog.schreib(this,"-","WICHTIG","Botschutz-Eskalation beendet ("+grund+")");
  protokoll(this,"WICHTIG","botschutz","Eskalation beendet ("+grund+")");
 }
 private void botschutzTakt(){
  if(botschutzSeit==0)return;
  long jetzt=System.currentTimeMillis();
  // Vordergrund heisst gesehen - alles andere waere Schikane.
  if(GameWebViewActivity.imVordergrundIrgendwo()){ botschutzBeenden("Spielansicht im Vordergrund"); return; }
  if(botschutzGesehenAm>botschutzSeit){ botschutzBeenden("quittiert"); return; }
  if(jetzt-botschutzLetzteVib>=nbBotVibSek*1000L){
   botschutzLetzteVib=jetzt;
   try{
    android.os.Vibrator v=(android.os.Vibrator)getSystemService(Context.VIBRATOR_SERVICE);
    if(v!=null&&v.hasVibrator())
     v.vibrate(android.os.VibrationEffect.createWaveform(new long[]{0,400,200,400},-1));
   }catch(Exception ignored){}
   long minuten=(jetzt-botschutzSeit)/60000L;
   zeigeFest(ID_BOTSCHUTZ,CH_ALERT,"Botschutz aktiv",
     botschutzText+" · seit "+minuten+" Min",true);
  }
  // Nach der eingestellten Zeit der Wecker - im Alarmkanal, damit er auch
  // bei stummgestelltem Klingelton laut ist.
  if(jetzt-botschutzSeit>=nbBotWeckerMin*60_000L&&botschutzKlang==null){
   try{
    android.net.Uri u=android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM);
    botschutzKlang=android.media.RingtoneManager.getRingtone(this,u);
    if(botschutzKlang!=null){
     botschutzKlang.setAudioAttributes(new android.media.AudioAttributes.Builder()
       .setUsage(android.media.AudioAttributes.USAGE_ALARM)
       .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION).build());
     if(Build.VERSION.SDK_INT>=28)botschutzKlang.setLooping(true);
     botschutzKlang.play();
     OdinLog.schreib(this,"-","WICHTIG","Botschutz-Wecker gestartet");
     protokoll(this,"WICHTIG","botschutz","Wecker gestartet nach "+nbBotWeckerMin+" Min");
    }
   }catch(Exception e){ android.util.Log.w("ODIN_SVC","wecker",e); }
  }
 }
 // Meldung mit fester Nummer: dieselbe Nummer ersetzt die vorige.
 private void zeigeFest(int id,String kanal,String titel,String text,boolean bleibt){
  try{
   Intent open=new Intent(this,MainActivity.class);
   open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
   PendingIntent pi=PendingIntent.getActivity(this,id,open,
     PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   Notification.Builder b=new Notification.Builder(this,kanal)
     .setContentTitle(titel).setContentText(text).setContentIntent(pi)
     .setStyle(new Notification.BigTextStyle().bigText(text))
     .setSmallIcon(android.R.drawable.ic_dialog_info)
     .setOnlyAlertOnce(!bleibt)
     .setAutoCancel(!bleibt);
   if(bleibt)b.setOngoing(true);
   getSystemService(NotificationManager.class).notify(id,b.build());
  }catch(Exception e){ android.util.Log.w("ODIN_SVC","zeigeFest",e); }
 }
 // Benutzt du das Geraet gerade? Dann nicht ins Vollbild draengen.
 private static long letztesWecken=0L;
 private static String letzterWeckSchluessel="";
 static boolean inBenutzung(Context c){
  try{
   android.os.PowerManager pm=(android.os.PowerManager)c.getSystemService(Context.POWER_SERVICE);
   android.app.KeyguardManager km=c.getSystemService(android.app.KeyguardManager.class);
   return pm!=null&&pm.isInteractive()&&(km==null||!km.isKeyguardLocked());
  }catch(Exception e){ return false; }
 }
 // DER EINZIGE WEG, eine Ansicht zu wecken. Dienstschleife und
 // Wecker-Empfaenger gehen beide hier durch.
 //
 // Vorher hatte jeder seine eigene Fassung: der Dienst fragte hoeflich nach
 // dem Geraetezustand, der Empfaenger holte die App ungefragt ins Vollbild -
 // samt Vollbild-Benachrichtigung. Lief dieselbe Sache ueber beide Wege,
 // gewann der unhoefliche. Zwei Mechanismen, nie gegeneinander geprueft.
 // Die Ansicht ueber den Sperrbildschirm holen. Nachweislich funktioniert
 // das NUR ueber die Vollbild-Benachrichtigung ("Wecker: über Sperrbildschirm,
 // dunkel"). Die Dimm-Rueckholung startete die Ansicht bis 1.68 direkt - am
 // 23.09. 18:26-18:43 zehnmal "vorn=false": Android liess sie hinter dem
 // Sperrbildschirm. Jetzt nehmen beide denselben Weg.
 // NO_USER_ACTION: sonst meldet Android der bereits offenen Ansicht einen
 // "Benutzer verlaesst"-Vorgang samt onUserInteraction() - das brach bis 1.68
 // jedes Weckfenster in derselben Sekunde ab.
 static void vollbildStarten(Context c,Intent i,String titel,String text){
  i.addFlags(Intent.FLAG_ACTIVITY_NO_USER_ACTION);
  PendingIntent pi=PendingIntent.getActivity(c,4242,i,
    PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
  Notification n=new Notification.Builder(c,CH_WAKE)
    .setContentTitle(titel).setContentText(text)
    .setSmallIcon(android.R.drawable.ic_dialog_info)
    .setCategory(Notification.CATEGORY_ALARM)
    .setFullScreenIntent(pi,true)
    .setAutoCancel(true).build();
  c.getSystemService(NotificationManager.class)
   .notify((int)(System.currentTimeMillis()%90000),n);
  c.startActivity(i);
 }
 static void wecken(Context c,String konto,String text,String art,boolean wartung){
  String fremd=fremdHalter(konto);
  if(fremd!=null){
   OdinLog.schreib(c,"-","info","Wecken uebersprungen ("+art+") - Konto läuft auf "+fremd);
   return;
  }
  String kt=konto==null?"":konto;
  // Dienstschleife und Wecker koennen denselben Termin sekundenversetzt
  // ausloesen. Ohne diese Sperre kaeme die Ansicht zweimal nach vorn.
  synchronized(OdinService.class){
   // Der Text gehoerte NICHT in den Schluessel: die beiden Wege bauen ihn
   // verschieden. Der Wecker meldet "FetterOrk · de256 · Raubzug", die
   // Dienstschleife "FetterOrk · de256" - verschiedene Schluessel, Sperre
   // wirkungslos. Am 20.09. um 02:57:35 und 02:57:36 zweimal geweckt.
   // Konto und Art reichen: zwei verschiedene Termine derselben Art
   // innerhalb einer Minute sollen die Ansicht ohnehin nur einmal holen.
   String schluessel=kt+"|"+art;
   long jetzt=System.currentTimeMillis();
   if(schluessel.equals(letzterWeckSchluessel)&&jetzt-letztesWecken<60_000L){
    OdinLog.schreib(c,"-","info","Wecken uebersprungen ("+art+") - vor <60 s schon geweckt");
    return;
   }
   letzterWeckSchluessel=schluessel; letztesWecken=jetzt;
  }
  // Im Dimm-Modus liegt die Ansicht bereits sichtbar vorn und laeuft im
  // vollen Takt - jedes Wecken wuerde sie nur herausreissen.
  if(GameWebViewActivity.dimmLaeuft(kt)){
   OdinLog.schreib(c,"-","info","Dimm-Modus läuft ("+art+") - kein Wecken nötig");
   protokoll(c,"info","wecker","Dimm-Modus läuft ("+art+") - kein Wecken nötig");
   return;
  }
  // Die Seite muss sichtbar sein, damit die Zeitgeber laufen - das leistet
  // auch das kleine schwebende Fenster, ohne dir dazwischenzufunken.
  if(inBenutzung(c)&&GameWebViewActivity.weckeLeise(kt)){
   OdinLog.schreib(c,"-","WICHTIG","Weckt leise ("+art+"): "+text);
   protokoll(c,"WICHTIG","wecker","Weckt leise ("+art+"): "+text);
   return;
  }
  OdinLog.schreib(c,"-","WICHTIG","Weckt ("+art+"): "+text);
  protokoll(c,"WICHTIG","wecker","Weckt ("+art+"): "+text);
  try{
   Intent i=new Intent(c,GameWebViewActivity.class);
   i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
             |Intent.FLAG_ACTIVITY_SINGLE_TOP);
   if(!kt.isEmpty()){
    i.setData(android.net.Uri.parse("odin://account/"+kt));
    i.putExtra("accountId",kt);
   }
   i.putExtra("fromAlarm",true);
   i.putExtra("wartung",wartung);
   vollbildStarten(c,i,wartung?"Raubzug fällig":"Termin fällig",text);
  }catch(Exception ex){
   OdinLog.schreib(c,"-","FEHLER","Wecken fehlgeschlagen: "+ex.getMessage());
  }
 }
 // Faellige Termine, die der Dienst SELBST ausloest.
 //
 // Auswertung ueber 14 Stunden: der Dienst meldete sich durchgehend alle
 // fuenf Minuten, auch bei gesperrtem Handy - waehrend kein einziger Alarm
 // des AlarmManagers ankam, weder Testalarm noch Wachhund noch Termin.
 // Die eigene Schleife ist auf diesem Geraet also der verlaessliche Weg.
 // Die Alarme bleiben als zweites Standbein bestehen.
 private final java.util.TreeMap<Long,String[]> faellig=new java.util.TreeMap<>();
 private long zuletztGeweckt=0L, letzteAuffrischung=0L;
 // Benachrichtigungseinstellungen des Teams. Werden beim Neusetzen der Wecker
 // mitgeladen; bis dahin gelten diese Vorgaben.
 private volatile boolean nbVorwarnAn=true, nbAngriffeGebuendelt=true, nbBotschutzAn=true;
 private volatile int nbVorwarnMin=3, nbBotVibSek=60, nbBotWeckerMin=10;
 private void einstellungenLaden(){
  try{
   JSONArray a=new JSONArray(hole("notification_settings?select=*&team_id=eq."
     +java.net.URLEncoder.encode(team,"UTF-8")));
   if(a.length()==0)return;
   JSONObject o=a.getJSONObject(0);
   nbVorwarnAn=o.optBoolean("vorwarnung_an",true);
   nbVorwarnMin=Math.max(1,Math.min(60,o.optInt("vorwarnung_min",3)));
   nbAngriffeGebuendelt=o.optBoolean("angriffe_gebuendelt",true);
   nbBotschutzAn=o.optBoolean("botschutz_an",true);
   nbBotVibSek=Math.max(10,Math.min(3600,o.optInt("botschutz_vibration_sek",60)));
   nbBotWeckerMin=Math.max(1,Math.min(120,o.optInt("botschutz_wecker_min",10)));
  }catch(Exception e){ android.util.Log.w("ODIN_SVC","nb-einstellungen",e); }
 }
 private void faelligPruefen(){
  long jetzt=System.currentTimeMillis();
  // Nicht oefter als alle zwei Minuten wecken, sonst haengt das Geraet fest.
  if(jetzt-zuletztGeweckt<90_000L)return;
  java.util.Map.Entry<Long,String[]> e;
  synchronized(faellig){ e=faellig.firstEntry(); }
  if(e==null||e.getKey()>jetzt)return;
  synchronized(faellig){ faellig.remove(e.getKey()); }
  zuletztGeweckt=jetzt;
  String konto=e.getValue()[0], text=e.getValue()[1], art=e.getValue()[2];
  wecken(this,konto,text,art,"Raubzug".equals(art));
 }
 // Der Dimm-Modus soll die Nacht durchhalten. Faellt die Ansicht aus dem
 // Vordergrund - Prozesstod, fremde App, ausgeschalteter Bildschirm -, holt
 // der Dienst sie zurueck. Ueber dem Sperrbildschirm ist das zulaessig, weil
 // "Über anderen Apps anzeigen" erteilt ist; dieselbe Berechtigung nutzt das
 // schwebende Fenster. Entsperrt wird dabei nichts.
 private long letzterDimmStart=0L;
 private void dimmWaechter(){
  android.content.SharedPreferences p=getSharedPreferences("odin_svc",Context.MODE_PRIVATE);
  if(!p.getBoolean("dimm_an",false))return;
  String konto=p.getString("dimm_konto","");
  if(GameWebViewActivity.dimmLaeuft(konto))return;
  long jetzt=System.currentTimeMillis();
  // Nicht im Kreis starten, falls das Holen scheitert.
  if(jetzt-letzterDimmStart<120_000L)return;
  letzterDimmStart=jetzt;
  try{
   Intent i=new Intent(this,GameWebViewActivity.class);
   i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
             |Intent.FLAG_ACTIVITY_SINGLE_TOP);
   if(!konto.isEmpty()){
    i.setData(android.net.Uri.parse("odin://account/"+konto));
    i.putExtra("accountId",konto);
   }
   i.putExtra("dimm",true);
   vollbildStarten(this,i,"Odin","Dimm-Modus wird fortgesetzt");
   // Nur der Startversuch - ob er ankommt, meldet die Ansicht selbst
   // ("Dimm-Kontrolle (Rückholung)").
   OdinLog.schreib(this,"-","WICHTIG","Dimm-Modus nicht vorn - Rückholung angestoßen");
   protokoll(this,"WICHTIG","wecker","Dimm-Modus nicht vorn - Rückholung angestoßen");
  }catch(Exception ex){
   OdinLog.schreib(this,"-","FEHLER","Dimm-Modus holen fehlgeschlagen: "+ex.getMessage());
  }
 }
 private void loop(){
  int runde=0;
  while(running){
   try{ poll(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","poll",e); }
   try{ faelligPruefen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","faellig",e); }
   try{ dimmWaechter(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","dimm",e); }
   try{ ueberfaelligPruefen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","ueberfaellig",e); }
   try{ leasePflegen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","lease",e); }
   try{ vorwarnPruefen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","vorwarnung",e); }
   try{ botschutzTakt(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","botschutz",e); }
   try{ authPruefen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","auth",e); }
   // Nach ZEIT auffrischen, nicht nach Rundenzahl. Seit die Schleife vor
   // Terminen auf fuenf Sekunden taktet, waren zehn Runden nur noch 50
   // Sekunden - der Dienst holte die Plaene fuenfmal in sechs Minuten.
   long jetzt=System.currentTimeMillis();
   if(jetzt-letzteAuffrischung>=300_000L){
    letzteAuffrischung=jetzt;
    try{ weckerNeuSetzen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","alarm",e); }
   }
   runde++;
   // Kurz vor einem Termin feiner takten: 30 s Raster wuerden sonst bis zu
   // 30 s vom 90-Sekunden-Vorlauf fressen.
   long schlaf=30000L;
   try{
    java.util.Map.Entry<Long,String[]> n;
    synchronized(faellig){ n=faellig.firstEntry(); }
    if(n!=null){
     long hin=n.getKey()-System.currentTimeMillis();
     if(hin<180000L)schlaf=5000L;
    }
   }catch(Exception ignored){}
   try{ Thread.sleep(schlaf); }catch(InterruptedException e){ return; }
  }
 }
 // Bisher protokollierte der Dienst nur nach Logcat - genau der Teil, der im
 // Hintergrund arbeitet, war im Protokoll unsichtbar. Ohne das laesst sich
 // nicht feststellen, ob ueberhaupt Wecker gesetzt werden.
 // Die Netzanfrage laeuft in einem eigenen Faden. Vorher lief sie auf dem
 // aufrufenden Thread - im Wecker-Empfaenger ist das der Hauptthread, und
 // Android wirft dort NetworkOnMainThreadException. Der Empfaenger war
 // deshalb im Protokoll VOLLSTAENDIG unsichtbar, obwohl er feuerte. Genau
 // dieselbe Falle wie beim ersten Testalarm: das Messwerkzeug hatte den
 // Fehler, den es messen sollte.
 static void protokoll(Context c,String stufe,String bereich,String text){
  final Context ctx=c.getApplicationContext();
  ladeStatisch(c);
  new Thread(()->protokollJetzt(ctx,stufe,bereich,text)).start();
 }
 private static void protokollJetzt(Context c,String stufe,String bereich,String text){
  try{
   ladeStatisch(c);
   if(url.isEmpty()||token.isEmpty()||team.isEmpty())return;
   JSONObject r=new JSONObject();
   r.put("team_id",team); r.put("level",stufe); r.put("bereich",bereich);
   r.put("message",text.length()>500?text.substring(0,500):text);
   r.put("device",Build.MODEL); r.put("app_version","dienst");
   HttpURLConnection x=(HttpURLConnection)new URL(url+"/rest/v1/app_events").openConnection();
   x.setRequestMethod("POST"); x.setRequestProperty("apikey",key);
   x.setRequestProperty("Authorization","Bearer "+token);
   x.setRequestProperty("Content-Type","application/json");
   x.setRequestProperty("Prefer","return=minimal");
   x.setConnectTimeout(15000); x.setReadTimeout(20000); x.setDoOutput(true);
   java.io.OutputStream os=x.getOutputStream();
   os.write(new JSONArray().put(r).toString().getBytes("UTF-8")); os.close();
   int st=x.getResponseCode();
   // Genau hier verschwand der abgelaufene Token: der Rueckgabewert wurde
   // geholt und weggeworfen. Einmal erneuern und wiederholen; beim zweiten
   // Mal greift die 20-s-Sperre in erneuern(), es gibt also keine Schleife.
   if(st>=200&&st<400)erfolg();
   if((st==401||st==403)&&erneuern(c,"protokoll"))protokollJetzt(c,stufe,bereich,text);
  }catch(Exception e){ android.util.Log.w("ODIN_SVC","protokoll",e); }
 }
 // Termine aus dem Rausstell-Plan in die eigene Liste uebernehmen.
 private void merkeTermine(String planJson,String konto,String bez){
  try{
   JSONObject root=new JSONObject(planJson);
   JSONArray doerfer=root.optJSONArray("attacks"); if(doerfer==null)return;
   long jetzt=System.currentTimeMillis();
   synchronized(faellig){
    for(int i=0;i<doerfer.length();i++){
     JSONObject d=doerfer.optJSONObject(i); if(d==null)continue;
     JSONArray list=d.optJSONArray("attacks"); if(list==null)continue;
     for(int k=0;k<list.length();k++){
      JSONObject a=list.optJSONObject(k); if(a==null)continue;
      long at=a.optLong("atMs",0L); if(at<=0)continue;
      long weck=at-OdinAlarm.VORLAUF_MS;
      if(weck<=jetzt)continue;
      faellig.put(weck,new String[]{konto,bez+" · "+d.optString("coord",""),"Termin"});
     }
    }
   }
  }catch(Exception e){ android.util.Log.w("ODIN_SVC","merkeTermine",e); }
 }
 private String hole(String pfad) throws Exception {
  String s=holeEinmal(pfad);
  if(s==null){ if(!erneuern(this,"hole "+pfad))return "[]"; s=holeEinmal(pfad); }
  return s==null?"[]":s;
 }
 // null heisst abgelehnt (401/403) - dann Token erneuern und genau einmal
 // wiederholen. "[]" heisst: Anfrage lief, lieferte aber nichts Brauchbares.
 private String holeEinmal(String pfad) throws Exception {
  HttpURLConnection c=(HttpURLConnection)new URL(url+"/rest/v1/"+pfad).openConnection();
  c.setRequestProperty("apikey",key); c.setRequestProperty("Authorization","Bearer "+token);
  c.setConnectTimeout(15000); c.setReadTimeout(20000);
  int st=c.getResponseCode();
  if(st==401||st==403)return null;
  if(st>=400)return "[]";
  erfolg();
  BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),"UTF-8"));
  StringBuilder b=new StringBuilder(); String l; while((l=r.readLine())!=null)b.append(l); r.close();
  return b.toString();
 }
 // Wecker fuer ALLE Accounts des Teams. Echte Parallelitaet gibt es nicht -
 // nur die sichtbare WebView laeuft ungedrosselt. Stattdessen wird jeweils
 // der Account nach vorne geholt, der als naechstes einen Termin hat.
 private void weckerNeuSetzen() throws Exception {
  if(url.isEmpty()||token.isEmpty()||team.isEmpty()){
   android.util.Log.w("ODIN_ALARM","keine Sitzung - keine Wecker");
   return;
  }
  einstellungenLaden();
  JSONArray accs=new JSONArray(hole("game_accounts?select=id,name,world&team_id=eq."
    +java.net.URLEncoder.encode(team,"UTF-8")));
  OdinAlarm.zuruecksetzen(this);
  synchronized(faellig){ faellig.clear(); }
  int gesamt=0, uebersprungen=0;
  for(int i=0;i<accs.length();i++){
   JSONObject a=accs.getJSONObject(i);
   String id=a.optString("id",""); if(id.isEmpty())continue;
   String bez=a.optString("name","")+" · "+a.optString("world","");
   JSONArray s=new JSONArray(hole("godbot_settings?select=value&skey=eq.tw_tabben_plan&account_id=eq."
     +java.net.URLEncoder.encode(id,"UTF-8")));
   // Accounts ohne GodBot-Daten kosten sonst drei Abfragen alle fuenf
   // Minuten fuer nichts - rund 860 am Tag je Account.
   if(s.length()==0){ uebersprungen++; continue; }
   merkeTermine(s.getJSONObject(0).optString("value","{}"),id,bez);
   gesamt+=OdinAlarm.planen(this,s.getJSONObject(0).optString("value","{}"),id,bez);
   // Alle Planungszeitpunkte, die GodBot selbst vormerkt. Einzeln
   // nachzuruesten hiesse, bei jeder neuen Funktion wieder etwas zu
   // vergessen - deshalb in einem Rutsch.
   try{
    // Nur echte kuenftige Zeitpunkte. tw_am_check_at und tw_plan_aufraeumen_at
    // halten den LETZTEN Lauf - sie standen hier bis 1.69 und wurden nur
    // deshalb nie zum Problem, weil vergangene Zeitpunkte verworfen werden.
    String liste="tw_next_recheck_at,tw_next_farm_burst_at,tw_next_resource_scan_at,"
                +"tw_am_check_soon_at,tw_incoming_rename_due_at,tw_mass_support_next_at";
    JSONArray nx=new JSONArray(hole("godbot_settings?select=skey,value&account_id=eq."
      +java.net.URLEncoder.encode(id,"UTF-8")
      +"&skey=in.("+java.net.URLEncoder.encode(liste,"UTF-8")+")"));
    long jetzt=System.currentTimeMillis();
    for(int n=0;n<nx.length();n++){
     JSONObject o=nx.getJSONObject(n);
     String sk=o.optString("skey","");
     double ms;
     try{ ms=Double.parseDouble(o.optString("value","0").replace("\"","")); }catch(Exception ig){ continue; }
     if(ms<=0)continue;
     long weck=(long)ms-20_000L;
     if(weck<=jetzt)continue;
     String art=sk.contains("recheck")?"Raubzug":sk.contains("farm")?"Farmen"
               :sk.contains("resource")?"Rohstoffe":sk.contains("am_check")?"Manager"
               :sk.contains("mass_support")?"Massenunterstützung"
               :sk.contains("rename")?"Eingehende":"Aufräumen";
     synchronized(faellig){ faellig.put(weck,new String[]{id,bez,art}); }
     if("Raubzug".equals(art))gesamt+=OdinAlarm.wartungPlanen(this,(long)ms,id,bez);
    }
   }catch(Exception e){ android.util.Log.w("ODIN_ALARM","planzeiten",e); }
  }
  // Direkt gemeldete Termine ueberstehen das Neuaufsetzen der Liste.
  appTermineEinplanen(0L,"","");
  android.util.Log.i("ODIN_ALARM","Wecker gesetzt: "+gesamt+" ueber "+accs.length()+" Accounts");
  int offen; synchronized(faellig){ offen=faellig.size(); }
  // Auch oertlich festhalten. Bisher sah ich nur, dass keine Meldungen
  // ankommen - nicht, ob der Dienst tot ist oder bloss kein Netz hat. Das
  // Geraeteprotokoll braucht kein Netz und unterscheidet beides.
  OdinLog.schreib(this,"-","info","Dienst lebt · "+offen+" Termine vorgemerkt");
  protokoll(this,(gesamt>0||offen>0)?"WICHTIG":"FEHLER","wecker",
    "Termine: "+offen+" vorgemerkt, "+gesamt+" Alarme, "
    +uebersprungen+" Accounts ohne Daten übersprungen");
 }
 private void poll() throws Exception {
  if(url.isEmpty()||token.isEmpty()||team.isEmpty())return;
  String since=lastSeen.isEmpty()
    ? new java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss",java.util.Locale.US)
        .format(new java.util.Date(System.currentTimeMillis()-60000))
    : lastSeen;
  String q=url+"/rest/v1/notifications?select=*&team_id=eq."+team
    +"&created_at=gt."+java.net.URLEncoder.encode(since,"UTF-8")
    +"&order=created_at.asc&limit=20";
  HttpURLConnection c=(HttpURLConnection)new URL(q).openConnection();
  c.setRequestProperty("apikey",key); c.setRequestProperty("Authorization","Bearer "+token);
  c.setConnectTimeout(15000); c.setReadTimeout(20000);
  int st=c.getResponseCode();
  if(st==401||st==403){ erneuern(this,"poll"); return; }
  if(st>=400)return;
  erfolg();
  BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),"UTF-8"));
  StringBuilder b=new StringBuilder(); String l; while((l=r.readLine())!=null)b.append(l); r.close();
  JSONArray arr=new JSONArray(b.toString());
  for(int i=0;i<arr.length();i++){
   JSONObject o=arr.getJSONObject(i);
   lastSeen=o.optString("created_at",lastSeen);
   // Eigene Meldungen nicht erneut anzeigen.
   if(device.equals(o.optString("source","")))continue;
   show(o.optString("title","Odin"),o.optString("body",""),o.optString("level","info"));
  }
 }
 // Eingehende Angriffe kommen im Schwung. Einzelne Meldungen dafuer sind
 // unbrauchbar: dreissig Zeilen, von denen man keine liest. Stattdessen EINE
 // Meldung, die mitzaehlt und die letzten Zeilen zeigt.
 private final java.util.ArrayDeque<String> angriffe=new java.util.ArrayDeque<>();
 private long angriffeSeit=0L;
 // Nur EINGEHENDE Angriffe. Das alte Muster "angriff" traf jede Farmrunde -
 // GodBots Meldung lautet "FarmGod schickt ... Angriffe ab" - und damit
 // kam bei jedem automatischen Farmen eine Benachrichtigung. GodBot selbst
 // meldet eingehende Angriffe nur als "AG-Alarm"; der Rest deckt Meldungen
 // aus anderen Quellen ab. "Angriffe ab" (ausgehend) trifft nichts davon.
 private static final java.util.regex.Pattern IST_ANGRIFF=
   java.util.regex.Pattern.compile("(?i)eingehend|incoming|ag-alarm|angegriffen|angriffe? auf ");
 // Entwarnung und Abschaltung erwaehnen den Botschutz ebenfalls - "Entwarnung
 // - Botschutz geloest" haette die Eskalation GESTARTET statt beendet.
 private static final java.util.regex.Pattern IST_ENTWARNUNG=
   java.util.regex.Pattern.compile("(?i)entwarnung|gelöst|geloest|eingestellt");
 private static final java.util.regex.Pattern IST_BOTSCHUTZ=
   java.util.regex.Pattern.compile("(?i)botschutz|captcha|bot.?schutz|bot protection");
 private boolean angriffSammeln(String title,String body){
  long jetzt=System.currentTimeMillis();
  synchronized(angriffe){
   // Nach zwei Stunden Ruhe faengt die Zaehlung neu an, sonst steht dort
   // morgen noch die Zahl von gestern.
   if(jetzt-angriffeSeit>2*60*60*1000L){ angriffe.clear(); angriffeSeit=jetzt; }
   angriffe.addLast(body==null||body.isEmpty()?title:body);
   while(angriffe.size()>8)angriffe.removeFirst();
   StringBuilder sb=new StringBuilder();
   for(String z:angriffe){ if(sb.length()>0)sb.append("\n"); sb.append(z); }
   zeigeFest(ID_ANGRIFFE,CH_ALERT,angriffe.size()+" eingehende Angriffe",sb.toString(),false);
  }
  return true;
 }
 private void show(String title,String body,String level){
  String zusammen=(title==null?"":title)+" "+(body==null?"":body);
  if(IST_BOTSCHUTZ.matcher(zusammen).find()&&IST_ENTWARNUNG.matcher(zusammen).find()){
   botschutzBeenden("Entwarnung von GodBot");
  }else if(nbBotschutzAn&&IST_BOTSCHUTZ.matcher(zusammen).find())botschutzStarten(title);
  if(nbAngriffeGebuendelt&&IST_ANGRIFF.matcher(zusammen).find()){ angriffSammeln(title,body); return; }
  // Routine bleibt stumm. Der Loader stuft Farmen, Raubzug, Statistiken und
  // Rohstoffe als "info" ein - dafuer eine Benachrichtigung zu bauen, ist
  // schon auf dem eigenen Geraet laestig und ueber das Team erst recht:
  // jede Meldung von Ares20 landete hier genauso. Nur warn und alert melden
  // sich, und die gehen ohnehin vorher in Botschutz oder Angriffsbuendelung.
  if(!"alert".equalsIgnoreCase(level)&&!"warn".equalsIgnoreCase(level))return;
  NotificationManager nm=getSystemService(NotificationManager.class);
  Intent open=new Intent(this,MainActivity.class);
  open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
  PendingIntent pi=PendingIntent.getActivity(this,0,open,
    PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
  Notification n=new Notification.Builder(this,"alert".equals(level)||"warn".equals(level)?CH_ALERT:CH_STATUS)
    .setContentTitle(title).setContentText(body).setContentIntent(pi)
    .setStyle(new Notification.BigTextStyle().bigText(body))
    .setSmallIcon(android.R.drawable.ic_dialog_info).setAutoCancel(true).build();
  nm.notify((int)(System.currentTimeMillis()%100000),n);
 }
 @Override public void onDestroy(){
  lauf=null;
  running=false; if(poller!=null)poller.interrupt();
  try{ if(lock!=null&&lock.isHeld())lock.release(); }catch(Exception ignored){}
  super.onDestroy();
 }
}
EOF
cat > "$JAVA_DIR/OdinMark.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import android.graphics.*; import android.view.View;
// Valknut - Odins Zeichen, drei verschlungene Dreiecke.
//
// Als reine Linienzeichnung auf schwarzem Grund leuchten nur wenige Pixel.
// Auf OLED kostet das kaum Strom, waehrend eine Flaeche oder eine Animation
// deutlich mehr zieht. Statisch, also auch keine Rechenlast.
public class OdinMark extends View {
 private final Paint stift=new Paint(Paint.ANTI_ALIAS_FLAG);
 public OdinMark(Context c){
  super(c);
  stift.setStyle(Paint.Style.STROKE);
  stift.setStrokeWidth(3.5f);
  stift.setStrokeJoin(Paint.Join.ROUND);
  stift.setColor(0xFFC9C9C9);
 }
 public void setFarbe(int f){ stift.setColor(f); invalidate(); }

 @Override protected void onDraw(Canvas k){
  float b=getWidth(), h=getHeight();
  float r=Math.min(b,h)*0.30f;      // Umkreis eines Dreiecks
  float d=r*0.60f;                  // Versatz der drei Mittelpunkte
  // Die Figur reicht von -(d+r) bis +(0.5d+0.5r) um den Bezugspunkt, sitzt
  // also um 0.25*(d+r) zu hoch. Das wird hier ausgeglichen.
  float cx=b/2f, cy=h/2f+0.25f*(d+r);
  // Drei gleichseitige Dreiecke, deren Mittelpunkte um 120 Grad versetzt
  // liegen - dadurch ueberlappen die Kanten und ergeben das verschlungene Bild.
  for(int i=0;i<3;i++){
   double m=Math.toRadians(90+i*120);
   float mx=cx+(float)Math.cos(m)*d, my=cy-(float)Math.sin(m)*d;
   Path p=new Path();
   for(int e=0;e<3;e++){
    double a=Math.toRadians(90+e*120);
    float x=mx+(float)Math.cos(a)*r, y=my-(float)Math.sin(a)*r;
    if(e==0)p.moveTo(x,y); else p.lineTo(x,y);
   }
   p.close();
   k.drawPath(p,stift);
  }
 }
}
EOF
cat > "$JAVA_DIR/OdinLog.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import java.io.*; import java.text.SimpleDateFormat;
import java.util.*;
// Dauerhaftes Protokoll auf dem Geraet.
//
// Die Statuszeile zeigt nur den letzten Vorgang und verschwindet beim Neustart.
// Hier landet alles mit Zeitstempel, Account und Stufe - genau das, womit wir
// die bisherigen Fehler gefunden haben, nur ohne dass es verlorengeht.
public final class OdinLog {
 private OdinLog(){}
 private static final String DATEI="odin-protokoll.txt";
 private static final int MAX_ZEILEN=800;
 private static final Object schloss=new Object();

 public static void schreib(Context c,String account,String stufe,String text){
  String zeile="["+new SimpleDateFormat("dd.MM. HH:mm:ss",Locale.GERMANY).format(new Date())+"] "
    +(stufe==null?"info":stufe)+" · "+(account==null||account.isEmpty()?"-":account)+" · "+text;
  synchronized(schloss){
   try{
    File f=new File(c.getFilesDir(),DATEI);
    List<String> alle=lesenIntern(f);
    alle.add(zeile);
    // Ringpuffer: aeltestes faellt raus, damit die Datei nicht waechst.
    while(alle.size()>MAX_ZEILEN)alle.remove(0);
    BufferedWriter w=new BufferedWriter(new OutputStreamWriter(new FileOutputStream(f,false),"UTF-8"));
    for(String z:alle){ w.write(z); w.newLine(); }
    w.close();
   }catch(Exception e){ android.util.Log.e("ODIN_LOG","schreib",e); }
  }
 }
 private static List<String> lesenIntern(File f) {
  List<String> alle=new ArrayList<>();
  if(!f.exists())return alle;
  try{
   BufferedReader r=new BufferedReader(new InputStreamReader(new FileInputStream(f),"UTF-8"));
   String l; while((l=r.readLine())!=null)alle.add(l); r.close();
  }catch(Exception ignored){}
  return alle;
 }
 public static String lesen(Context c){
  synchronized(schloss){
   List<String> alle=lesenIntern(new File(c.getFilesDir(),DATEI));
   if(alle.isEmpty())return "(noch nichts protokolliert)";
   StringBuilder b=new StringBuilder();
   // Neueste zuerst - beim Suchen nach einem Fehler will man den Schluss.
   for(int i=alle.size()-1;i>=0;i--)b.append(alle.get(i)).append('\n');
   return b.toString();
  }
 }
 public static void leeren(Context c){
  synchronized(schloss){ new File(c.getFilesDir(),DATEI).delete(); }
 }
}
EOF
cat > "$JAVA_DIR/ParallelTestActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.Activity; import android.app.ActivityManager; import android.content.Context;
import android.os.Bundle; import android.view.View; import android.view.WindowManager;
import android.webkit.*; import android.widget.*;
import org.json.JSONArray; import org.json.JSONObject;
// TESTFASSUNG: mehrere Welten gleichzeitig in EINER Ansicht, ohne GodBot.
// Frage: laufen alle gezeichneten WebViews ungedrosselt, wie viel Speicher
// kostet jede Welt, und meldet das Spiel eine Welt ab, wenn eine zweite
// denselben Login benutzt? Jede Kachel misst jede Sekunde ihren Zeitgeber
// und meldet einmal pro Minute ins Protokoll:
//   Takt 60/60 (ungedrosselt) - weniger heisst gedrosselt.
public class ParallelTestActivity extends Activity {
 private final java.util.List<WebView> views=new java.util.ArrayList<>();
 private View decke; private TextView kopf;
 private final android.os.Handler h=new android.os.Handler(android.os.Looper.getMainLooper());
 private static final String PROBE="(function(){try{if(window.__odinProbe)return;window.__odinProbe=1;"
  +"var n=0,s=0,m=0,l=Date.now();"
  +"setInterval(function(){var t=Date.now(),d=t-l-1000;l=t;if(d<0)d=0;n++;s+=d;if(d>m)m=d;},1000);"
  +"setInterval(function(){var mem=(window.performance&&performance.memory&&performance.memory.usedJSHeapSize)||0;"
  +"var gd=window.game_data;var an=!!(gd&&gd.player&&gd.player.id);"
  +"OdinProbe.bericht(JSON.stringify({n:n,avg:n?Math.round(s/n):-1,max:m,vis:document.visibilityState,"
  +"mem:Math.round(mem/1048576),an:an,welt:(gd&&gd.world)||location.host,spieler:(gd&&gd.player&&gd.player.name)||''}));"
  +"n=0;s=0;m=0;},60000);}catch(e){}})();";
 private class Probe {
  private final String name;
  Probe(String n){ name=n; }
  @JavascriptInterface public void bericht(String json){
   try{
    JSONObject o=new JSONObject(json);
    String t="Takt "+o.optInt("n")+"/60, Abweichung Ø"+o.optInt("avg")+" max "+o.optInt("max")+" ms, "
      +o.optString("vis")+", JS "+(o.optInt("mem")>0?o.optInt("mem")+" MB":"?")+", "
      +(o.optBoolean("an")?"angemeldet ("+o.optString("spieler")+")":"NICHT angemeldet")+" · "+o.optString("welt");
    OdinLog.schreib(ParallelTestActivity.this,"Parallel "+name,o.optInt("n")>=55?"info":"WICHTIG",t);
   }catch(Exception ignored){}
  }
 }
 @Override protected void onCreate(Bundle b){
  super.onCreate(b);
  getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  FrameLayout rahmen=new FrameLayout(this);
  LinearLayout aussen=new LinearLayout(this); aussen.setOrientation(LinearLayout.VERTICAL);
  LinearLayout leiste=new LinearLayout(this); leiste.setOrientation(LinearLayout.HORIZONTAL);
  kopf=new TextView(this); kopf.setTextSize(12f); kopf.setPadding(12,8,12,8);
  Button ab=new Button(this); ab.setText("Abdecken"); ab.setAllCaps(false); ab.setTextSize(12f);
  Button ende=new Button(this); ende.setText("Beenden"); ende.setAllCaps(false); ende.setTextSize(12f);
  leiste.addView(kopf,new LinearLayout.LayoutParams(0,-2,1f)); leiste.addView(ab); leiste.addView(ende);
  aussen.addView(leiste,new LinearLayout.LayoutParams(-1,-2));
  LinearLayout spalte=new LinearLayout(this); spalte.setOrientation(LinearLayout.VERTICAL);
  aussen.addView(spalte,new LinearLayout.LayoutParams(-1,0,1f));
  rahmen.addView(aussen,new FrameLayout.LayoutParams(-1,-1));
  setContentView(rahmen);
  JSONArray konten;
  try{ konten=new JSONArray(getIntent().getStringExtra("konten")); }catch(Exception e){ konten=new JSONArray(); }
  StringBuilder t=new StringBuilder("Test: ");
  for(int i=0;i<konten.length()&&i<3;i++){
   JSONObject k=konten.optJSONObject(i); if(k==null)continue;
   String id=k.optString("id",""), name=k.optString("name",""), welt=GameWebViewActivity.normWelt(k.optString("world",""));
   if(id.isEmpty()||welt.isEmpty())continue;
   WebView v=new WebView(this);
   String profil="Standard";
   try{
    if(androidx.webkit.WebViewFeature.isFeatureSupported(androidx.webkit.WebViewFeature.MULTI_PROFILE)){
     profil=OdinVault.profilName(this,id);
     androidx.webkit.ProfileStore.getInstance().getOrCreateProfile(profil);
     androidx.webkit.WebViewCompat.setProfile(v,profil);
    }
   }catch(Exception e){ profil="Fehler: "+e.getMessage(); }
   WebSettings s=v.getSettings(); s.setJavaScriptEnabled(true); s.setDomStorageEnabled(true);
   CookieManager.getInstance().setAcceptCookie(true);
   CookieManager.getInstance().setAcceptThirdPartyCookies(v,true);
   final String kurz=(name.isEmpty()?welt:name)+"@"+welt;
   v.addJavascriptInterface(new Probe(kurz),"OdinProbe");
   v.setWebViewClient(new WebViewClient(){
    @Override public void onPageFinished(WebView w,String u){ w.evaluateJavascript(PROBE,null); }
   });
   OdinLog.schreib(this,"Parallel "+kurz,"info","Kachel "+(i+1)+": Profil "+profil);
   v.loadUrl("https://"+welt+".die-staemme.de/game.php");
   spalte.addView(v,new LinearLayout.LayoutParams(-1,0,1f));
   views.add(v);
   t.append(i>0?" | ":"").append(kurz);
  }
  kopf.setText(t.toString());
  // Abdecken wie im Dimm-Modus: schwarze Flaeche davor, Helligkeit aus.
  // Die WebViews darunter werden weiter gezeichnet.
  decke=new View(this); decke.setBackgroundColor(0xFF000000); decke.setVisibility(View.GONE);
  decke.setOnClickListener(x->abdecken(false));
  rahmen.addView(decke,new FrameLayout.LayoutParams(-1,-1));
  ab.setOnClickListener(x->abdecken(true));
  ende.setOnClickListener(x->finish());
  h.postDelayed(speicher,60_000L);
 }
 private void abdecken(boolean an){
  decke.setVisibility(an?View.VISIBLE:View.GONE);
  WindowManager.LayoutParams lp=getWindow().getAttributes();
  lp.screenBrightness=an?0f:WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
  getWindow().setAttributes(lp);
  OdinLog.schreib(this,"-","info","Parallel-Test: "+(an?"abgedeckt":"aufgedeckt"));
 }
 // Einmal pro Minute: freier Geraetespeicher und Speicher des App-Prozesses.
 // Der Renderer der WebViews laeuft in einem eigenen Prozess; seinen Anteil
 // zeigt der freie Geraetespeicher im Vergleich zum Start.
 private long startFrei=-1;
 private final Runnable speicher=new Runnable(){ @Override public void run(){
  try{
   ActivityManager am=(ActivityManager)getSystemService(Context.ACTIVITY_SERVICE);
   ActivityManager.MemoryInfo mi=new ActivityManager.MemoryInfo(); am.getMemoryInfo(mi);
   long frei=mi.availMem/1048576L; if(startFrei<0)startFrei=frei;
   long app=android.os.Debug.getPss()/1024L;
   OdinLog.schreib(ParallelTestActivity.this,"-","info","Parallel-Test Speicher: frei "+frei+" MB (Start "+startFrei
     +"), App "+app+" MB, "+views.size()+" Welt(en)"+(mi.lowMemory?" - KNAPP":""));
  }catch(Exception ignored){}
  h.postDelayed(this,60_000L);
 }};
 @Override protected void onDestroy(){
  h.removeCallbacksAndMessages(null);
  for(WebView v:views){ try{ v.destroy(); }catch(Exception ignored){} }
  super.onDestroy();
 }
}
EOF
cat > "$JAVA_DIR/OdinVault.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import android.content.SharedPreferences;
import android.security.keystore.KeyGenParameterSpec; import android.security.keystore.KeyProperties;
import android.util.Base64;
import java.security.KeyStore;
import javax.crypto.*; import javax.crypto.spec.GCMParameterSpec;
// Zugangsdaten der Spielaccounts - ausschliesslich auf DIESEM Geraet.
//
// Bewusst nicht in der geteilten Datenbank: dort waeren sie fuer jedes
// Teammitglied lesbar, und ein einziger Fehler in einer RLS-Regel oder ein
// abhandengekommener Anon-Key legt dann nicht ein Passwort offen, sondern alle.
// Der Schluessel liegt im Android-Keystore und verlaesst das Geraet nie.
public final class OdinVault {
 private OdinVault(){}
 private static final String ALIAS="odin_vault", PREFS="odin_vault_prefs";
 private static SecretKey key() throws Exception {
  KeyStore ks=KeyStore.getInstance("AndroidKeyStore"); ks.load(null);
  if(ks.containsAlias(ALIAS)) return ((KeyStore.SecretKeyEntry)ks.getEntry(ALIAS,null)).getSecretKey();
  KeyGenerator kg=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");
  kg.init(new KeyGenParameterSpec.Builder(ALIAS,
    KeyProperties.PURPOSE_ENCRYPT|KeyProperties.PURPOSE_DECRYPT)
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE).build());
  return kg.generateKey();
 }
 private static SharedPreferences p(Context c){ return c.getSharedPreferences(PREFS,Context.MODE_PRIVATE); }

 public static void speichern(Context c,String accountId,String benutzer,String passwort){
  try{
   Cipher ci=Cipher.getInstance("AES/GCM/NoPadding");
   ci.init(Cipher.ENCRYPT_MODE,key());
   byte[] iv=ci.getIV();
   byte[] ct=ci.doFinal((benutzer+"\u0000"+passwort).getBytes("UTF-8"));
   byte[] all=new byte[iv.length+ct.length];
   System.arraycopy(iv,0,all,0,iv.length); System.arraycopy(ct,0,all,iv.length,ct.length);
   p(c).edit().putString(accountId,Base64.encodeToString(all,Base64.NO_WRAP))
              .putInt(accountId+"_ivlen",iv.length).apply();
  }catch(Exception e){ android.util.Log.e("ODIN_VAULT","speichern",e); }
 }
 // [0] Benutzer, [1] Passwort - oder null.
 public static String[] lesen(Context c,String accountId){
  try{
   String b64=p(c).getString(accountId,null); if(b64==null)return null;
   int ivlen=p(c).getInt(accountId+"_ivlen",12);
   byte[] all=Base64.decode(b64,Base64.NO_WRAP);
   byte[] iv=new byte[ivlen]; System.arraycopy(all,0,iv,0,ivlen);
   byte[] ct=new byte[all.length-ivlen]; System.arraycopy(all,ivlen,ct,0,ct.length);
   Cipher ci=Cipher.getInstance("AES/GCM/NoPadding");
   ci.init(Cipher.DECRYPT_MODE,key(),new GCMParameterSpec(128,iv));
   String[] teile=new String(ci.doFinal(ct),"UTF-8").split("\u0000",2);
   return teile.length==2?teile:null;
  }catch(Exception e){ android.util.Log.e("ODIN_VAULT","lesen",e); return null; }
 }
 public static boolean vorhanden(Context c,String accountId){ return p(c).contains(accountId); }
 // WebView-Profil je Staemme-LOGIN statt je Odin-Konto. Mehrere Welten mit
 // demselben Login teilen sich ein Profil - wie mehrere Tabs im selben
 // Browser: eine Anmeldung, gemeinsame Cookies. Ein anderer Login bekommt
 // sein eigenes Profil und laeuft getrennt daneben.
 //
 // Der Name bleibt "acc_<id>" des Kontos, das den Login zuerst benutzt hat.
 // So behaelt ein bestehendes Konto sein Profil samt Anmeldung und
 // GodBot-Daten; neue Welten desselben Logins haengen sich daran. Ohne
 // hinterlegte Zugangsdaten bleibt es beim Profil je Konto wie bisher.
 public static String profilName(Context c,String accountId){
  String eigen="acc_"+accountId.replaceAll("[^A-Za-z0-9]","");
  try{
   String[] ich=lesen(c,accountId);
   if(ich==null||ich[0]==null||ich[0].trim().isEmpty())return eigen;
   String login=ich[0].trim().toLowerCase(java.util.Locale.ROOT);
   SharedPreferences zp=c.getSharedPreferences("odin_profile",Context.MODE_PRIVATE);
   String fest=zp.getString("login:"+login,"");
   if(!fest.isEmpty())return fest;
   java.util.List<String> da=new java.util.ArrayList<>();
   try{ da.addAll(androidx.webkit.ProfileStore.getInstance().getAllProfileNames()); }catch(Exception ignored){}
   String wahl=eigen;
   if(!da.contains(eigen)){
    for(String k:p(c).getAll().keySet()){
     if(k.endsWith("_ivlen")||k.equals(accountId))continue;
     String[] t=lesen(c,k);
     if(t==null||t[0]==null||!login.equals(t[0].trim().toLowerCase(java.util.Locale.ROOT)))continue;
     String kand="acc_"+k.replaceAll("[^A-Za-z0-9]","");
     if(da.contains(kand)){ wahl=kand; break; }
    }
   }
   zp.edit().putString("login:"+login,wahl).apply();
   return wahl;
  }catch(Exception e){ return eigen; }
 }
 public static void loeschen(Context c,String accountId){
  p(c).edit().remove(accountId).remove(accountId+"_ivlen").apply();
 }
}
EOF
cat > "$JAVA_DIR/OdinJob.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.job.*; import android.content.ComponentName; import android.content.Context;
import android.content.Intent;
// Wiederbeleber auf einem ANDEREN System als der AlarmManager.
//
// Befund aus der Nacht: der Dienst meldete sich bis 00:54 alle fuenf Minuten
// und war dann sechs Stunden weg. Der Wachhund haengt am AlarmManager, und
// der feuert auf diesem Geraet nachweislich nie - in ueber 24 Stunden kein
// einziger Treffer, auch nicht beim reinen Testalarm.
//
// JobScheduler ist ein eigener Mechanismus mit eigener Drosselung. Kuerzeste
// zulaessige Wiederholung sind 15 Minuten; das genuegt, um den Dienst
// zurueckzuholen, der dann seine Termine selbst wieder einliest.
public class OdinJob extends JobService {
 private static final int ID=4711;
 public static void planen(Context c){
  try{
   JobScheduler js=(JobScheduler)c.getSystemService(Context.JOB_SCHEDULER_SERVICE);
   if(js==null)return;
   JobInfo j=new JobInfo.Builder(ID,new ComponentName(c,OdinJob.class))
     .setPeriodic(15*60*1000L)
     .setPersisted(true)          // ueberlebt den Neustart des Geraets
     .setRequiredNetworkType(JobInfo.NETWORK_TYPE_ANY)
     .build();
   js.schedule(j);
  }catch(Exception e){ android.util.Log.e("ODIN_JOB","planen",e); }
 }
 @Override public boolean onStartJob(JobParameters p){
  try{
   OdinService.ladeStatisch(this);
   startForegroundService(new Intent(this,OdinService.class));
   OdinLog.schreib(this,"-","info","Job: Dienst nachgestartet");
   OdinService.protokoll(this,"info","job","Dienst nachgestartet");
  }catch(Exception e){ android.util.Log.w("ODIN_JOB","start",e); }
  return false;   // keine Hintergrundarbeit im Job selbst
 }
 @Override public boolean onStopJob(JobParameters p){ return true; }
}
EOF
cat > "$JAVA_DIR/OdinBootReceiver.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.BroadcastReceiver; import android.content.Context; import android.content.Intent;
// Wecker des AlarmManagers ueberleben einen Neustart des Geraets nicht, und
// nach einem App-Update sind sie ebenfalls weg. Der Dienst wird deshalb wieder
// gestartet und setzt die Wecker beim naechsten Durchlauf neu.
public class OdinBootReceiver extends BroadcastReceiver {
 @Override public void onReceive(Context c, Intent in){
  try{ c.startForegroundService(new Intent(c,OdinService.class)); }
  catch(Exception e){ android.util.Log.w("ODIN_BOOT","start",e); }
  OdinJob.planen(c);
 }
}
EOF
cat > "$JAVA_DIR/OdinAlarm.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.AlarmManager; import android.app.PendingIntent;
import android.content.Context; import android.content.Intent; import android.os.Build;
import org.json.*;
// Weckt zum Termin, auch bei gesperrtem Bildschirm.
//
// Grundlage sind die ohnehin abgeglichenen Rausstell-Plaene: in
// tw_tabben_plan steht je Eintrag attacks[].attacks[].atMs, der
// Einschlagszeitpunkt in Millisekunden. Geweckt wird VORLAUF_MS davor,
// damit GodBot die Seite laden und handeln kann.
public final class OdinAlarm {
 private OdinAlarm(){}
 public static final long VORLAUF_MS = 90_000L;   // 90 s vor Einschlag
 private static final int MAX_WECKER = 12;        // Android begrenzt exakte Alarme
 public static final String EXTRA_AT="odin_at", EXTRA_INFO="odin_info",
   EXTRA_ACCOUNT="odin_account", EXTRA_WARTUNG="odin_wartung",
   EXTRA_WACHHUND="odin_wachhund";
 // Fortlaufende Kennung ueber alle Accounts hinweg, damit sich die Wecker
 // verschiedener Konten nicht gegenseitig ueberschreiben.
 private static int naechsteId=9000;
 public static synchronized void zuruecksetzen(Context c){ naechsteId=9000; }

 public static boolean exactAllowed(Context c){
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   return Build.VERSION.SDK_INT<31 || am.canScheduleExactAlarms();
  }catch(Exception e){ return false; }
 }

 // Einzelner Testwecker, um die Kette ohne Warten auf einen echten Termin
 // zu pruefen: Alarm -> Bildschirm an -> Spielansicht im Vordergrund.
 @SuppressWarnings("unused") public static long test(Context c, int sekunden){
  long at=System.currentTimeMillis()+sekunden*1000L;
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   Intent i=new Intent(c,OdinAlarmReceiver.class);
   i.putExtra(EXTRA_AT,at); i.putExtra(EXTRA_INFO,"Testwecker");
   PendingIntent pi=PendingIntent.getBroadcast(c,8999,i,
     PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   if(exactAllowed(c)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,at,pi);
   else am.set(AlarmManager.RTC_WAKEUP,at,pi);
  }catch(Exception e){ android.util.Log.e("ODIN_ALARM","test",e); return 0L; }
  return at;
 }

 // Wachhund. Der Vordergrunddienst wird auf manchen Geraeten trotz
 // START_STICKY abgeraeumt und kommt nicht von selbst zurueck - im Protokoll
 // waren das 7,5 Stunden ohne eine einzige Meldung. Alarme des AlarmManagers
 // ueberleben dagegen den Prozesstod. Dieser Alarm startet den Dienst neu und
 // setzt sich anschliessend selbst wieder.
 public static final String EXTRA_PROBE="odin_probe";
 // Testalarm zum Isolieren einer einzigen Frage: feuert der AlarmManager auf
 // diesem Geraet ueberhaupt? Er oeffnet nichts und weckt nichts - er schreibt
 // nur eine Zeile ins Protokoll, samt tatsaechlicher Verspaetung.
 public static long probe(Context c,int sekunden){
  long at=System.currentTimeMillis()+sekunden*1000L;
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   Intent i=new Intent(c,OdinAlarmReceiver.class);
   i.putExtra(EXTRA_PROBE,at);
   i.setData(android.net.Uri.parse("odin://probe/"+at));
   PendingIntent pi=PendingIntent.getBroadcast(c,6666,i,
     PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   if(exactAllowed(c)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,at,pi);
   else am.set(AlarmManager.RTC_WAKEUP,at,pi);
  }catch(Exception e){ android.util.Log.e("ODIN_ALARM","probe",e); return 0L; }
  return at;
 }
 public static final long WACHHUND_MS=15*60_000L;
 public static void wachhund(Context c){
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   Intent i=new Intent(c,OdinAlarmReceiver.class);
   i.putExtra(EXTRA_WACHHUND,true);
   i.setData(android.net.Uri.parse("odin://wachhund"));
   PendingIntent pi=PendingIntent.getBroadcast(c,7777,i,
     PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   long at=System.currentTimeMillis()+WACHHUND_MS;
   if(exactAllowed(c)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,at,pi);
   else am.set(AlarmManager.RTC_WAKEUP,at,pi);
  }catch(Exception e){ android.util.Log.e("ODIN_ALARM","wachhund",e); }
 }

 // Wartungswecker: GodBot berechnet den naechsten Raubzug-Durchlauf selbst und
 // legt ihn in tw_next_recheck_at ab (Millisekunden). Wir wecken kurz davor,
 // statt starr alle 30 Minuten - so gibt es nur so viele Aufwachvorgaenge wie
 // noetig. tw_loop_active=1 heisst, der Kreislauf laeuft ueberhaupt.
 public static synchronized int wartungPlanen(Context c,long naechsterLaufMs,String accountId,String bez){
  long jetzt=System.currentTimeMillis();
  long weck=naechsterLaufMs-20_000L;      // 20 s Vorlauf zum Laden
  if(naechsterLaufMs<=0||weck<=jetzt+5000L)return 0;
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   Intent i=new Intent(c,OdinAlarmReceiver.class);
   i.putExtra(EXTRA_AT,naechsterLaufMs); i.putExtra(EXTRA_INFO,bez+" · Raubzug");
   i.putExtra(EXTRA_ACCOUNT,accountId==null?"":accountId);
   i.putExtra(EXTRA_WARTUNG,true);
   i.setData(android.net.Uri.parse("odin://wartung/"+accountId));
   PendingIntent pi=PendingIntent.getBroadcast(c,naechsteId++,i,
     PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
   if(exactAllowed(c)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,weck,pi);
   else am.set(AlarmManager.RTC_WAKEUP,weck,pi);
   return 1;
  }catch(Exception e){ android.util.Log.e("ODIN_ALARM","wartung",e); return 0; }
 }

 // Liefert die Anzahl gesetzter Wecker zurueck.
 public static int planen(Context c, String tabbenPlanJson, String accountId, String bezeichnung){
  int gesetzt=0;
  try{
   AlarmManager am=(AlarmManager)c.getSystemService(Context.ALARM_SERVICE);
   JSONObject root=new JSONObject(tabbenPlanJson);
   JSONArray doerfer=root.optJSONArray("attacks"); if(doerfer==null)return 0;
   java.util.TreeMap<Long,String> termine=new java.util.TreeMap<>();
   long jetzt=System.currentTimeMillis();
   for(int i=0;i<doerfer.length();i++){
    JSONObject d=doerfer.optJSONObject(i); if(d==null)continue;
    String coord=d.optString("coord","");
    JSONArray list=d.optJSONArray("attacks"); if(list==null)continue;
    for(int k=0;k<list.length();k++){
     JSONObject a=list.optJSONObject(k); if(a==null)continue;
     long at=a.optLong("atMs",0L); if(at<=0)continue;
     long weck=at-VORLAUF_MS;
     if(weck<=jetzt+5000L)continue;            // zu knapp oder vorbei
     termine.put(weck, bezeichnung+" · "+coord+" · "+a.optString("slowestUnit",""));
    }
   }
   for(java.util.Map.Entry<Long,String> e:termine.entrySet()){
    if(gesetzt>=MAX_WECKER)break;
    Intent i=new Intent(c,OdinAlarmReceiver.class);
    i.putExtra(EXTRA_AT,e.getKey()+VORLAUF_MS); i.putExtra(EXTRA_INFO,e.getValue());
    i.putExtra(EXTRA_ACCOUNT,accountId==null?"":accountId);
    // Eigene Daten-URI, sonst gilt bei PendingIntent nur die Kennung und
    // gleichartige Intents verschiedener Konten wuerden verschmelzen.
    i.setData(android.net.Uri.parse("odin://wecker/"+accountId+"/"+e.getKey()));
    PendingIntent pi=PendingIntent.getBroadcast(c,naechsteId++,i,
      PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
    try{
     if(exactAllowed(c)) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,e.getKey(),pi);
     else am.set(AlarmManager.RTC_WAKEUP,e.getKey(),pi);
     gesetzt++;
    }catch(SecurityException se){
     // Ohne Recht auf exakte Alarme lieber ungenau wecken als gar nicht.
     am.set(AlarmManager.RTC_WAKEUP,e.getKey(),pi); gesetzt++;
    }
   }
  }catch(Exception e){ android.util.Log.e("ODIN_ALARM","planen",e); }
  return gesetzt;
 }
}
EOF
cat > "$JAVA_DIR/OdinAlarmReceiver.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.*; import android.content.BroadcastReceiver; import android.content.Context;
import android.content.Intent;
// Holt die App zum Termin nach vorne - wie ein Wecker, auch ueber dem
// Sperrbildschirm. Erst dadurch wird die WebView sichtbar und die
// Zeitgeber laufen wieder exakt.
public class OdinAlarmReceiver extends BroadcastReceiver {
 @Override public void onReceive(Context c, Intent in){
  // Zuerst die Sitzung: ohne sie ist der Wecker stumm und die Ansicht kann
  // nichts abgleichen.
  OdinService.ladeStatisch(c);
  // Lief der Dienst schon? Nur dann ist "nachgestartet" wahr. Bisher stand
  // die Zeile alle 15 Minuten im Protokoll, ob der Dienst tot war oder nicht.
  final boolean warTot=OdinService.lauf==null;
  try{ c.startForegroundService(new Intent(c,OdinService.class)); }
  catch(Exception e){ android.util.Log.w("ODIN_ALARM","dienst",e); }
  long probeZiel=in.getLongExtra(OdinAlarm.EXTRA_PROBE,0L);
  if(probeZiel>0){
   long spaet=(System.currentTimeMillis()-probeZiel)/1000;
   // ZUERST oertlich schreiben: im Doze-Modus ist der Netzzugriff fuer
   // Hintergrund-Apps gesperrt. Ein Alarm kann also feuern, ohne dass die
   // Meldung ankommt - genau daran ist der erste Test gescheitert.
   OdinLog.schreib(c,"-","WICHTIG","Testalarm gefeuert, Verspätung "+spaet+" s");
   OdinService.protokoll(c,"WICHTIG","probe","Testalarm gefeuert, Verspätung "+spaet+" s");
   return;
  }
  if(in.getBooleanExtra(OdinAlarm.EXTRA_WACHHUND,false)){
   // Nur den Dienst zurueckholen und sich selbst neu setzen - kein Spiel
   // oeffnen, kein Bildschirm an.
   OdinAlarm.wachhund(c);
   if(warTot){
    OdinLog.schreib(c,"-","WICHTIG","Wachhund: Dienst war beendet - nachgestartet");
    OdinService.protokoll(c,"WICHTIG","wachhund","Dienst war beendet - nachgestartet");
   }
   return;
  }
  String info=in.getStringExtra(OdinAlarm.EXTRA_INFO); if(info==null)info="";
  String acc=in.getStringExtra(OdinAlarm.EXTRA_ACCOUNT); if(acc==null)acc="";
  boolean wartung=in.getBooleanExtra(OdinAlarm.EXTRA_WARTUNG,false);
  OdinLog.schreib(c,"-","WICHTIG","Wecker ausgelöst ("+(wartung?"Raubzug":"Termin")+"): "+info);
  // Kein eigener Weg mehr: derselbe Aufruf wie in der Dienstschleife. Der
  // entscheidet, ob leise, gar nicht oder im Vordergrund geweckt wird.
  OdinService.wecken(c,acc,info,wartung?"Raubzug":"Termin",wartung);
 }
}
EOF
cat > "$JAVA_DIR/OdinSkripte.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import android.content.SharedPreferences;
import org.json.JSONArray; import org.json.JSONObject;
// Skriptverwaltung wie bei Tampermonkey: eine Liste, jeder Eintrag einzeln
// an- oder abschaltbar. Zwei Arten von Eintraegen:
//   quelle="url"  - wird geholt und eine Stunde zwischengespeichert
//   quelle="code" - der eingefuegte Text selbst
// GodBot steht NICHT in dieser Liste: er ist fester Bestandteil der App und
// liegt als Asset in der APK (godbot/GodBot.user.js im Repo). Kein Gist,
// kein Nachladen, keine Ablaufzeit - eine neue GodBot-Fassung kommt mit
// der naechsten App-Version.
public final class OdinSkripte {
 private OdinSkripte(){}
 private static final String PREFS="odin_skripte", KEY="liste";
 public static final String GODBOT_ID="godbot";
 private static SharedPreferences p(Context c){ return c.getSharedPreferences(PREFS,Context.MODE_PRIVATE); }
 // Oertlicher Notvorrat der Teamliste. Alte Fassungen hatten GodBot als
 // ersten Eintrag mit Gist-Adresse - der wird hier ausgefiltert.
 public static JSONArray liste(Context c){
  JSONArray out=new JSONArray();
  try{
   String roh=p(c).getString(KEY,"");
   if(roh!=null&&!roh.isEmpty()){
    JSONArray a=new JSONArray(roh);
    for(int i=0;i<a.length();i++){
     JSONObject o=a.optJSONObject(i); if(o==null)continue;
     if(istGodBotEintrag(o.optString("id",""),o.optString("url","")))continue;
     out.put(o);
    }
   }
  }catch(Exception ignored){}
  return out;
 }
 // Frueher eingetragener GodBot (Gist) - wird uebergangen, damit er nicht
 // doppelt laeuft.
 public static boolean istGodBotEintrag(String id,String url){
  return GODBOT_ID.equals(id)||(url!=null&&url.contains("GodBot.user.js"));
 }
 // --- eingebauter GodBot -------------------------------------------------
 // Einmal je Prozess aus der APK gelesen und als Bytes gehalten: die
 // Spielansicht liefert ihn bei jedem Seitenaufbau aus, 2,9 MB jedes Mal neu
 // zu kodieren waere Verschwendung.
 private static volatile String godbotText=null;
 private static volatile byte[] godbotBytes=null;
 public static String godbot(Context c){
  if(godbotText==null){
   synchronized(OdinSkripte.class){
    if(godbotText==null){
     try{
      java.io.InputStream in=c.getApplicationContext().getAssets().open("godbot.user.js");
      byte[] b=alles(in);
      godbotBytes=b;
      godbotText=new String(b,"UTF-8");
     }catch(Exception e){ android.util.Log.e("ODIN","godbot asset",e); godbotText=""; godbotBytes=new byte[0]; }
    }
   }
  }
  return godbotText;
 }
 public static byte[] godbotBytes(Context c){ godbot(c); return godbotBytes; }
 static byte[] alles(java.io.InputStream in) throws java.io.IOException{
  java.io.ByteArrayOutputStream o=new java.io.ByteArrayOutputStream(1<<20);
  byte[] buf=new byte[65536]; int n;
  while((n=in.read(buf))>0)o.write(buf,0,n);
  in.close();
  return o.toByteArray();
 }
 // --- Tampermonkey-Kopf --------------------------------------------------
 // Alle Werte eines Schluessels (@match, @include, @exclude, @require ...).
 public static java.util.List<String> meta(String code,String schluessel){
  java.util.List<String> out=new java.util.ArrayList<>();
  if(code==null)return out;
  int a=code.indexOf("==UserScript=="), b=code.indexOf("==/UserScript==");
  if(a<0||b<a)return out;
  String kopf=code.substring(a,b);
  java.util.regex.Matcher m=java.util.regex.Pattern
    .compile("(?m)^\\s*//\\s*@"+java.util.regex.Pattern.quote(schluessel)+"\\s+(.+?)\\s*$").matcher(kopf);
  while(m.find())out.add(m.group(1).trim());
  return out;
 }
 // Wie Tampermonkey: @exclude schlaegt alles, ohne @match/@include laeuft
 // das Skript ueberall (so verhielt sich Odin bisher fuer ALLE Skripte -
 // dadurch lief z. B. ein Karten-Skript auf jeder Seite und warf dort
 // "MapSdk is not defined").
 public static boolean passt(String code,String adresse){
  java.util.List<String> ein=meta(code,"match"); ein.addAll(meta(code,"include"));
  java.util.List<String> aus=meta(code,"exclude"); aus.addAll(meta(code,"exclude-match"));
  for(String e:aus)if(treffer(e,adresse))return false;
  if(ein.isEmpty())return true;
  for(String i:ein)if(treffer(i,adresse))return true;
  return false;
 }
 static boolean treffer(String muster,String adresse){
  try{
   String m=muster.trim();
   if(m.isEmpty())return false;
   if(m.equals("*")||m.equals("<all_urls>"))return true;
   // /regulaerer Ausdruck/ wie bei @include
   if(m.length()>2&&m.startsWith("/")&&m.endsWith("/"))
    return java.util.regex.Pattern.compile(m.substring(1,m.length()-1),java.util.regex.Pattern.CASE_INSENSITIVE)
      .matcher(adresse).find();
   if(glob(m,adresse))return true;
   // "*.die-staemme.de" soll auch "die-staemme.de" selbst treffen
   if(m.contains("://*."))return glob(m.replace("://*.","://"),adresse);
   return false;
  }catch(Exception e){ return false; }
 }
 static boolean glob(String m,String adresse){
  StringBuilder r=new StringBuilder("^");
  for(int i=0;i<m.length();i++){
   char ch=m.charAt(i);
   if(ch=='*')r.append(".*");
   else r.append(java.util.regex.Pattern.quote(String.valueOf(ch)));
  }
  r.append("$");
  return java.util.regex.Pattern.compile(r.toString(),java.util.regex.Pattern.CASE_INSENSITIVE).matcher(adresse).matches();
 }
 // Wie Tampermonkey jedes Skript in eine eigene Funktion. Ohne das teilen
 // sich alle Skripte den globalen Gueltigkeitsbereich: zwei Skripte mit
 // "let win" auf oberster Ebene werfen dann "already been declared".
 public static String einpacken(String code,String name){
  String n=(name==null?"skript":name).replaceAll("[^A-Za-z0-9_-]+","_");
  return "(function(){\n"+code+"\n})();\n//# sourceURL=odin-skript/"+n+".js\n";
 }
 // --- URL-Quellen und @require -------------------------------------------
 // Eine Stunde zwischengespeichert. Frueher wurde jede URL bei jedem
 // Seitenaufbau neu geholt.
 private static final long URL_MAX_ALTER_MS=60L*60L*1000L;
 private static final java.util.Map<String,String> URL_TEXT=new java.util.HashMap<>();
 private static final java.util.Map<String,Long> URL_ZEIT=new java.util.HashMap<>();
 public static String holeGecacht(String adresse){
  if(adresse==null||!adresse.startsWith("https://"))return null;
  long jetzt=System.currentTimeMillis();
  synchronized(URL_TEXT){
   Long z=URL_ZEIT.get(adresse);
   if(z!=null&&jetzt-z<URL_MAX_ALTER_MS)return URL_TEXT.get(adresse);
  }
  String t=null;
  try{
   java.net.HttpURLConnection c=(java.net.HttpURLConnection)new java.net.URL(adresse).openConnection();
   c.setInstanceFollowRedirects(true); c.setConnectTimeout(15000); c.setReadTimeout(30000);
   c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");
   int st=c.getResponseCode();
   if(st>=200&&st<300)t=new String(alles(c.getInputStream()),"UTF-8");
  }catch(Exception e){ android.util.Log.w("ODIN","holeGecacht "+adresse,e); }
  synchronized(URL_TEXT){
   if(t!=null&&!t.isEmpty()){ URL_TEXT.put(adresse,t); URL_ZEIT.put(adresse,jetzt); return t; }
   // Fehlschlag: alten Stand weiterverwenden, falls vorhanden
   return URL_TEXT.get(adresse);
  }
 }
 public static void speichern(Context c,JSONArray a){
  try{ p(c).edit().putString(KEY,a.toString()).apply(); }catch(Exception ignored){}
 }
 // Name aus dem Kopf des Skripts lesen, damit man nicht selbst tippen muss.
 public static String nameAus(String code){
  try{
   java.util.regex.Matcher m=java.util.regex.Pattern
     .compile("(?m)^\\s*//\\s*@name\\s+(.+)$").matcher(code==null?"":code);
   if(m.find())return m.group(1).trim();
  }catch(Exception ignored){}
  return "";
 }
 // @version aus dem Kopf. Genau daran erkennt auch Tampermonkey ein Update.
 public static String versionAus(String code){
  try{
   java.util.regex.Matcher m=java.util.regex.Pattern
     .compile("(?m)^\\s*//\\s*@version\\s+(.+)$").matcher(code==null?"":code);
   if(m.find())return m.group(1).trim();
  }catch(Exception ignored){}
  return "";
 }
 // Zuletzt gesehene Fassung je Eintrag - daraus ergibt sich, ob etwas neu ist.
 public static String letzteVersion(Context c,String id){
  return p(c).getString("ver_"+id,"");
 }
 public static void merkeVersion(Context c,String id,String v){
  try{ p(c).edit().putString("ver_"+id,v).apply(); }catch(Exception ignored){}
 }
 public static String neueId(){ return "s"+System.currentTimeMillis(); }
}
EOF
cat > "$JAVA_DIR/OdinFloat.java" <<'EOF'
package de.teamzentrale.odin;
import android.content.Context; import android.graphics.PixelFormat; import android.os.Build;
import android.provider.Settings; import android.view.*; import android.widget.*; import android.webkit.WebView;
import java.util.*;
// Schwebende Spielfenster - eines je Spielaccount, gleichzeitig moeglich.
//
// Chromium drosselt JS-Zeitgeber danach, ob eine WebView GERENDERT wird. Jedes
// Overlay ist ein eigenes sichtbares Fenster, also laufen mehrere Welten
// parallel im vollen Takt. Die WebView behaelt ihre Layoutgroesse und wird nur
// skaliert dargestellt, sonst baute die Spielseite auf Symbolbreite um und
// GodBots Selektoren griffen auf ein anderes Layout zu.
public final class OdinFloat {
 private OdinFloat(){}
 private static final int LAY_W=420, LAY_H=740;
 public static final int GROSS=150, KLEIN=44;   // Kantenlaenge in Pixeln
 private static class Fenster {
  View rahmen; WebView web; WindowManager wm;
 }
 private static final Map<String,Fenster> offen=new LinkedHashMap<>();

 public static boolean allowed(Context c){ return Settings.canDrawOverlays(c); }
 public static synchronized boolean active(String accountId){ return offen.containsKey(schluessel(accountId)); }
 public static synchronized int anzahl(){ return offen.size(); }
 private static String schluessel(String a){ return a==null||a.isEmpty()?"_":a; }

 public static synchronized boolean show(Context ctx,String accountId,WebView web,Runnable onRestore){
  return show(ctx,accountId,web,onRestore,GROSS);
 }
 // Fuer Aktionen im Hintergrund reicht ein sehr kleines Fenster: entscheidend
 // ist, dass die WebView GERENDERT wird, nicht wie gross sie ist.
 public static synchronized boolean show(Context ctx,String accountId,WebView web,Runnable onRestore,int win){
  final Context app=ctx.getApplicationContext();
  final String key=schluessel(accountId);
  if(offen.containsKey(key)||web==null||!allowed(app))return false;
  try{
   if(web.getParent() instanceof ViewGroup)((ViewGroup)web.getParent()).removeView(web);

   FrameLayout box=new FrameLayout(app);
   FrameLayout.LayoutParams wlp=new FrameLayout.LayoutParams(LAY_W,LAY_H);
   wlp.gravity=Gravity.CENTER;
   web.setLayoutParams(wlp);
   // Die WebView muss gerendert bleiben, darf aber nicht zu sehen sein. Sie
   // wird deshalb winzig in die Mitte skaliert - deutlich kleiner als der
   // Kreis darueber. Vorher fuellte sie das Fenster fast aus und schaute an
   // den Ecken unter dem runden Symbol hervor.
   web.setPivotX(LAY_W/2f); web.setPivotY(LAY_H/2f);
   float scale=(win*0.40f)/LAY_H;
   web.setScaleX(scale); web.setScaleY(scale);
   box.addView(web);

   TextView symbol=new TextView(app); symbol.setText("⚔");
   symbol.setTextColor(0xFFFFFFFF); symbol.setTextSize(win>=GROSS?24f:11f);
   symbol.setGravity(Gravity.CENTER);
   android.graphics.drawable.GradientDrawable g=new android.graphics.drawable.GradientDrawable();
   g.setShape(android.graphics.drawable.GradientDrawable.OVAL);
   g.setColor(0xFF2B2B2B); g.setStroke(win>=GROSS?4:2,0xFFE8E8E8); symbol.setBackground(g);
   symbol.setElevation(8f);   // liegt sicher ueber der WebView
   box.addView(symbol,new FrameLayout.LayoutParams(-1,-1));

   int type=Build.VERSION.SDK_INT>=26?WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                                     :WindowManager.LayoutParams.TYPE_PHONE;
   // Durchscheinend, damit ausserhalb des Kreises nichts steht - sonst waere
   // das Symbol ein schwarzes Quadrat.
   final WindowManager.LayoutParams lp=new WindowManager.LayoutParams(win,win,type,
     WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.TRANSLUCENT);
   // Das kleine Fenster oben an den Rand, auf Hoehe der Statusleiste. In die
   // Leiste selbst kann keine App zeichnen - das hier ist ein Overlay davor,
   // sieht aber aehnlich aus. Ein blosses Benachrichtigungssymbol wuerde
   // nichts nuetzen: es rendert die WebView nicht, und genau darauf kommt es
   // gegen die Drosselung an.
   if(win<GROSS){
    lp.gravity=Gravity.TOP|Gravity.END;
    lp.x=8+offen.size()*(win+8); lp.y=2;
   }else{
    lp.gravity=Gravity.TOP|Gravity.START;
    lp.x=16; lp.y=180+offen.size()*(win+24);
   }

   final WindowManager wm=(WindowManager)app.getSystemService(Context.WINDOW_SERVICE);
   final Fenster f=new Fenster(); f.web=web; f.wm=wm;

   symbol.setOnTouchListener(new View.OnTouchListener(){
    float dx,dy,sx,sy; boolean bewegt;
    @Override public boolean onTouch(View v,MotionEvent e){
     switch(e.getAction()){
      case MotionEvent.ACTION_DOWN:
       dx=lp.x-e.getRawX(); dy=lp.y-e.getRawY(); sx=e.getRawX(); sy=e.getRawY(); bewegt=false; return true;
      case MotionEvent.ACTION_MOVE:
       lp.x=(int)(e.getRawX()+dx); lp.y=(int)(e.getRawY()+dy);
       if(Math.abs(e.getRawX()-sx)>10||Math.abs(e.getRawY()-sy)>10)bewegt=true;
       try{wm.updateViewLayout(f.rahmen,lp);}catch(Exception ig){} return true;
      case MotionEvent.ACTION_UP:
       if(!bewegt&&onRestore!=null)onRestore.run();
       return true;
     }
     return false;
    }
   });

   wm.addView(box,lp); f.rahmen=box; offen.put(key,f);
   return true;
  }catch(Exception e){ android.util.Log.e("ODIN_FLOAT","show",e); entfernen(key); return false; }
 }

 // Gibt die WebView zurueck und setzt die Darstellung zurueck. Ohne das haengt
 // die Seite nach dem Maximieren verkleinert in der Ecke.
 public static synchronized WebView hide(String accountId){
  Fenster f=offen.get(schluessel(accountId));
  if(f==null)return null;
  WebView w=f.web;
  if(w!=null){ w.setScaleX(1f); w.setScaleY(1f); w.setPivotX(0f); w.setPivotY(0f); }
  entfernen(schluessel(accountId));
  return w;
 }
 private static void entfernen(String key){
  Fenster f=offen.remove(key); if(f==null)return;
  try{ if(f.web!=null&&f.web.getParent() instanceof ViewGroup)
        ((ViewGroup)f.web.getParent()).removeView(f.web); }catch(Exception ignored){}
  try{ if(f.rahmen!=null&&f.wm!=null)f.wm.removeView(f.rahmen); }catch(Exception ignored){}
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
 // Merkt sich, aus welcher Ansicht minimiert wurde, damit das Tippen genau
 // dorthin zurueckfuehrt statt eine neue Spielsitzung zu starten.
 private static Class<?> returnTo=MainActivity.class;
 private static String rueckKonto="";
 public static void setReturnTarget(Class<?> c){ if(c!=null)returnTo=c; }
 public static void setReturnTarget(Class<?> c,String konto){ if(c!=null)returnTo=c; rueckKonto=konto==null?"":konto; }
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
  TextView b=new TextView(app); b.setText("⚔"); b.setTextColor(Color.WHITE);
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
       Intent i=new Intent(app,returnTo);
       // Ohne Kennung entstuende eine neue, sitzungslose Ansicht.
       if(rueckKonto!=null&&!rueckKonto.isEmpty()){
        i.setData(android.net.Uri.parse("odin://account/"+rueckKonto));
        i.putExtra("accountId",rueckKonto);
       }
       i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                 |Intent.FLAG_ACTIVITY_SINGLE_TOP);
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
import android.annotation.SuppressLint; import android.app.Activity; import android.content.Context; import android.content.Intent; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.widget.LinearLayout; import android.widget.TextView; import android.widget.Button; import android.widget.HorizontalScrollView; import android.util.Log; import android.os.Build; import android.webkit.JavascriptInterface; import java.io.*; import java.net.*; import org.json.JSONObject;
public class GameWebViewActivity extends Activity {
 private WebView webView;
 private TextView statusView;
 // Teile fuer den Bootstrap in Ladereihenfolge: GodBot (aus der APK), dann
 // je eingeschaltetem Zusatzskript dessen @require und das Skript selbst.
 // Ausgeliefert unter /__odin_t_<i>.js.
 private volatile java.util.List<byte[]> godbotTeile=new java.util.ArrayList<>();
 private boolean godbotGemeldet=false;
 // Teamliste der Zusatzskripte: fuenf Minuten gueltig. Vorher kostete jeder
 // Seitenaufbau eine Supabase-Anfrage.
 private static org.json.JSONArray skriptListe=null;
 private static long skriptListeZeit=0L;
 private String supaUrl="",supaKey="",supaToken="",supaTeam="",gameAccountId="";
 private LinearLayout rootLayout;
 // Welche Ansicht gehoert zu welchem Account - verhindert Doppelstarts.
 private static final java.util.Map<String,GameWebViewActivity> OFFEN=new java.util.HashMap<>();
 private FrameLayout dimRahmen;
 private android.view.View dimDecke;
 // Nur wenn die Ansicht auch WIRKLICH vorn liegt, wird die WebView gerendert.
 // Ohne das koennte der Dimm-Modus "aktiv" melden, waehrend eine andere App
 // davor liegt und Chromium laengst drosselt.
 private volatile boolean imVordergrund=false;
 // Laeuft fuer diesen Account gerade der Dimm-Modus, sichtbar und gerendert?
 // Der Dienst fragt das, bevor er weckt - im Dimm-Modus ist nichts zu tun.
 static boolean dimmLaeuft(String accountId){
  try{
   GameWebViewActivity a=OFFEN.get(accountId==null?"":accountId);
   return a!=null&&!a.isFinishing()&&a.dimDecke!=null&&a.imVordergrund;
  }catch(Exception e){ return false; }
 }
 // Laeuft die Seite dieses Accounts gerade OHNE Drosselung? Genau drei Faelle
 // erfuellen das, und alle drei haben dieselbe Ursache: die WebView wird
 // tatsaechlich gezeichnet.
 //   1. Dimm-Modus  - Abdeckung liegt vorn, Bildschirm an
 //   2. Ansicht vorn - offen und im Vordergrund
 //   3. schwebendes Fenster UND Bildschirm an - ein Overlay bei dunklem
 //      Bildschirm wird nicht gezeichnet und zaehlt deshalb NICHT
 // Liegt IRGENDEINE Spielansicht vorn? Dafuer reicht ein Blick in die Liste
 // der offenen Ansichten - den Vordergrund einer fremden App kann eine App
 // ohne Nutzungsdaten-Berechtigung nicht abfragen.
 static boolean imVordergrundIrgendwo(){
  try{
   for(GameWebViewActivity a:OFFEN.values())
    if(a!=null&&!a.isFinishing()&&a.imVordergrund)return true;
  }catch(Exception ignored){}
  return false;
 }
 static boolean laeuftUngedrosselt(Context c,String accountId){
  try{
   String kt=accountId==null?"":accountId;
   if(dimmLaeuft(kt))return true;
   GameWebViewActivity a=OFFEN.get(kt);
   if(a!=null&&!a.isFinishing()&&a.imVordergrund)return true;
   if(OdinFloat.active(kt)){
    android.os.PowerManager pm=(android.os.PowerManager)c.getSystemService(Context.POWER_SERVICE);
    if(pm!=null&&pm.isInteractive())return true;
   }
  }catch(Exception ignored){}
  return false;
 }
 // Der Wunsch ueberlebt Prozesstod und Neustart - erst ein Tippen auf die
 // Abdeckung nimmt ihn zurueck.
 private boolean dimmGewuenscht(){
  try{ return getSharedPreferences("odin_svc",MODE_PRIVATE).getBoolean("dimm_an",false); }
  catch(Exception e){ return false; }
 }
 String apkVersion(){try{return getPackageManager().getPackageInfo(getPackageName(),0).versionName;}catch(Exception e){return "?";}}
 // Vollstaendiges Protokoll: die Statuszeile ist einzeilig und schneidet lange
 // Fehlermeldungen ab, deshalb wird alles mitgeschrieben und ist kopierbar.
 private final StringBuilder statusLog=new StringBuilder();
 void setStatus(String msg){
  synchronized(statusLog){
   if(statusLog.length()==0)statusLog.append("Odin APK ").append(apkVersion()).append('\n');
   statusLog.append('[').append(new java.text.SimpleDateFormat("HH:mm:ss",java.util.Locale.GERMANY)
     .format(new java.util.Date())).append("] ").append(msg).append('\n');
  }
  runOnUiThread(()->{if(statusView!=null)statusView.setText("APK "+apkVersion()+" · GodBot: "+msg);});
  android.util.Log.i("ODIN_GODBOT",msg);
  String stufe = (msg.contains("Fehler")||msg.contains("fehlgeschlagen")||msg.contains("Achtung")) ? "FEHLER"
               : (msg.contains("Zugangssperre")||msg.contains("Wecker")) ? "WICHTIG" : "info";
  OdinLog.schreib(this,kopfName+"#"+instanz,stufe,msg);
  // Alles wandert nach Odin, aber gebuendelt: einzelne Anfragen je Meldung
  // waeren zu viele. Die Warteschlange wird alle 30 s oder ab 25 Eintraegen
  // in einem Rutsch geschickt.
  ereignisMelden(stufe,bereichVon(msg),msg);
 }
 private static String bereichVon(String m){
  if(m.contains("Anmeldung"))return "anmeldung";
  if(m.contains("Wecker"))return "wecker";
  if(m.contains("Abgleich")||m.contains("Einstellungen"))return "abgleich";
  if(m.contains("Zugangssperre")||m.contains("Bruecke")||m.contains("Quelle"))return "godbot";
  return "app";
 }
 private final org.json.JSONArray warteschlange=new org.json.JSONArray();
 private long letzterVersand=0L;
 private void ereignisMelden(String stufe,String bereich,String text){
  if(supaUrl.isEmpty()||supaToken.isEmpty()||supaTeam.isEmpty())return;
  boolean jetztSenden;
  synchronized(warteschlange){
   try{
    org.json.JSONObject r=new org.json.JSONObject();
    r.put("team_id",supaTeam);
    if(!gameAccountId.isEmpty())r.put("account_id",gameAccountId);
    r.put("level",stufe); r.put("bereich",bereich+"/"+instanz);
    // Sehr lange Meldungen kuerzen, damit einzelne Zeilen die Tabelle nicht
    // aufblaehen - dieselbe Falle wie beim 288 KB grossen tw_console_log.
    r.put("message",text.length()>500?text.substring(0,500)+" …":text);
    r.put("device",android.os.Build.MODEL); r.put("app_version",apkVersion());
    warteschlange.put(r);
   }catch(Exception ignored){}
   long jetzt=System.currentTimeMillis();
   jetztSenden = warteschlange.length()>=25 || (jetzt-letzterVersand>30_000L&&warteschlange.length()>0);
   if(jetztSenden)letzterVersand=jetzt;
  }
  if(jetztSenden)warteschlangeLeeren();
 }
 void warteschlangeLeeren(){
  final String rumpf;
  synchronized(warteschlange){
   if(warteschlange.length()==0)return;
   rumpf=warteschlange.toString();
   for(int i=warteschlange.length()-1;i>=0;i--)warteschlange.remove(i);
  }
  new Thread(()->{
   try{ supaRequest("POST","app_events",rumpf); }
   catch(Exception e){ android.util.Log.w("ODIN_EVENT","melden",e); }
  }).start();
 }
 private String kopfName="";
 // Kurze Kennung je Ansicht. Ohne sie laesst sich bei doppelten Zeilen nicht
 // sagen, ob zwei Instanzen laufen oder eine zweimal meldet.
 private final String instanz=Integer.toHexString(System.identityHashCode(this)).substring(0,4);
 // Vollstaendiges Protokoll ansehen, kopieren oder leeren.
 private void protokollZeigen(){
  String text=OdinLog.lesen(this);
  android.widget.TextView tv=new android.widget.TextView(this);
  tv.setText(text); tv.setTextSize(11f); tv.setPadding(24,16,24,16);
  tv.setTextIsSelectable(true);
  android.widget.ScrollView sv=new android.widget.ScrollView(this); sv.addView(tv);
  new android.app.AlertDialog.Builder(this)
   .setTitle("Protokoll")
   .setView(sv)
   .setPositiveButton("Kopieren",(d,w)->{
     try{
      android.content.ClipboardManager cm=(android.content.ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
      cm.setPrimaryClip(android.content.ClipData.newPlainText("Odin-Protokoll",text));
      android.widget.Toast.makeText(this,"Protokoll kopiert ("+text.length()+" Zeichen)",
        android.widget.Toast.LENGTH_SHORT).show();
     }catch(Exception ignored){}
   })
   .setNeutralButton("Leeren",(d,w)->{ OdinLog.leeren(this); setStatus("Protokoll geleert"); })
   .setNegativeButton("Schließen",null)
   .show();
 }
 private void copyStatusLog(){
  String text;
  synchronized(statusLog){ text=statusLog.toString(); }
  try{
   android.content.ClipboardManager cm=(android.content.ClipboardManager)getSystemService(CLIPBOARD_SERVICE);
   cm.setPrimaryClip(android.content.ClipData.newPlainText("Odin GodBot-Protokoll",text));
   android.widget.Toast.makeText(this,"Protokoll kopiert ("+text.length()+" Zeichen)",
     android.widget.Toast.LENGTH_SHORT).show();
  }catch(Exception e){android.util.Log.e("ODIN_GODBOT","clipboard",e);}
 }
 @SuppressLint("SetJavaScriptEnabled") @Override protected void onCreate(Bundle b){super.onCreate(b); Fullscreen.apply(this); weckerModus();
  String activeName=getIntent().getStringExtra("username"); if(activeName==null||activeName.isEmpty())activeName=getIntent().getStringExtra("accountId"); if(activeName==null)activeName="";
  kopfName=activeName;
  String accountsJson=getIntent().getStringExtra("accountsJson"); if(accountsJson==null)accountsJson="[]";
  // Nur EINE Spielansicht je Account. Zwei Instanzen teilen sich dasselbe
  // WebView-Profil und damit denselben localStorage; GodBots eigene
  // Mehrfachstart-Sperre erkennt das und legt die Oberflaeche still.
  String wer=nz(getIntent().getStringExtra("accountId"));
  GameWebViewActivity vorhanden=OFFEN.get(wer);
  if(vorhanden!=null&&vorhanden!=this&&!vorhanden.isFinishing()){
   android.util.Log.i("ODIN_GODBOT","zweite Ansicht fuer "+wer+" verworfen");
   // Auch ins oertliche Protokoll: bisher ging diese Zeile nur nach Supabase
   // und war beim Auswerten der Geraeteprotokolle unsichtbar. Ob die Sperre
   // greift oder daneben, liess sich so gar nicht erkennen.
   OdinLog.schreib(this,wer,"WICHTIG",
     "zweite Ansicht verworfen (bestehend #"+vorhanden.instanz+", neu #"+instanz+")");
   OdinService.protokoll(this,"WICHTIG","doppelstart",
     "zweite Ansicht verworfen (bestehend #"+vorhanden.instanz+", neu #"+instanz+")");
   finish(); return;
  }
  // Wer hier eine bestehende Instanz ersetzt, ohne dass die Sperre oben
  // gegriffen hat, ist der Fall, den das Protokoll vom 20.09. zeigt:
  // #af2b -> #d35a -> #cf8a, jedes Mal ein frisches onCreate. Festhalten,
  // welche Instanz verdraengt wurde und in welchem Zustand sie war.
  GameWebViewActivity vorher=OFFEN.get(wer);
  if(vorher!=null&&vorher!=this){
   OdinLog.schreib(this,wer,"WICHTIG","Ansicht ersetzt: #"+vorher.instanz
     +" -> #"+instanz+" (alte beendet sich: "+vorher.isFinishing()+")");
  }
  OFFEN.put(wer,this);
  supaUrl=nz(getIntent().getStringExtra("supaUrl")); supaKey=nz(getIntent().getStringExtra("supaKey"));
  supaToken=nz(getIntent().getStringExtra("supaToken")); supaTeam=nz(getIntent().getStringExtra("supaTeam"));
  // Vom Wecker gestartet traegt das Intent keine Sitzung - dann aus der
  // dauerhaften Ablage holen, sonst laeuft die Ansicht ohne Abgleich.
  if(supaUrl.isEmpty()||supaToken.isEmpty())sitzungNachladen();
  gameAccountId=nz(getIntent().getStringExtra("accountId"));
  LinearLayout root=new LinearLayout(this); root.setOrientation(LinearLayout.VERTICAL); root.setBackgroundColor(0xFFFFFFFF);
  root.addView(buildHeader(activeName),new LinearLayout.LayoutParams(-1,-2));
  webView=new WebView(this);
  profilSetzen(webView,gameAccountId);
  root.addView(webView,new LinearLayout.LayoutParams(-1,0,1f));
  root.addView(buildFooter(accountsJson,activeName),new LinearLayout.LayoutParams(-1,-2));
  rootLayout=root;
  dimRahmen=new FrameLayout(this);
  dimRahmen.addView(root,new FrameLayout.LayoutParams(-1,-1));
  setContentView(dimRahmen);WebSettings s=webView.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setDatabaseEnabled(true);android.webkit.CookieManager.getInstance().setAcceptCookie(true);android.webkit.CookieManager.getInstance().setAcceptThirdPartyCookies(webView,true);s.setSupportMultipleWindows(true);s.setJavaScriptCanOpenWindowsAutomatically(true);webView.setWebChromeClient(new WebChromeClient(){@Override public boolean onConsoleMessage(ConsoleMessage m){Log.d("ODIN_JS",m.message()+" @"+m.lineNumber()+" "+m.sourceId());return true;}
 // Ohne diese Rueckgabe verschluckt die WebView alert/confirm der Bestaetigungsseite.
 @Override public boolean onJsAlert(WebView v,String u,String msg,JsResult res){res.confirm();return true;}
 @Override public boolean onJsConfirm(WebView v,String u,String msg,JsResult res){res.confirm();return true;}
 // Seitenwechsel-Sperre (1.81.0): GodBot haelt einen Seitenwechsel an, den
 // der Nutzer waehrend eines laufenden Vorgangs ausgeloest hat. Statt der
 // nackten Browser-Rueckfrage ein eigener Dialog mit klaren Knoepfen.
 // Wegtippen oder Zurueck = hierbleiben.
 @Override public boolean onJsBeforeUnload(WebView v,String u,String msg,JsResult res){
  runOnUiThread(()->{
   try{
    new android.app.AlertDialog.Builder(GameWebViewActivity.this)
     .setTitle("GodBot arbeitet gerade")
     .setMessage((msg==null||msg.trim().isEmpty())?"Ein Seitenwechsel jetzt bricht den laufenden Vorgang ab.":msg)
     .setPositiveButton("Hierbleiben",(d,w)->res.cancel())
     .setNegativeButton("Trotzdem wechseln",(d,w)->res.confirm())
     .setOnCancelListener(d->res.cancel())
     .show();
   }catch(Exception e){ res.confirm(); }
  });
  return true;
 }
 @Override public boolean onShowFileChooser(WebView v,ValueCallback<android.net.Uri[]> cb,FileChooserParams p){cb.onReceiveValue(null);return true;}
 @Override public void onPermissionRequest(final PermissionRequest r){runOnUiThread(()->r.deny());}});webView.addJavascriptInterface(new OdinNative(),"OdinNative");webView.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return false;}
 @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest r){anfrageZaehlen(r);WebResourceResponse x=odinIntercept(r);return x!=null?x:super.shouldInterceptRequest(v,r);}
 @Override public void onPageFinished(WebView v,String u){injectManagedScripts(v);anmeldenWennNoetig(v);loadEnabledScripts(v);}});String welt=normWelt(nz(getIntent().getStringExtra("world")));
  String lastGame=getSharedPreferences("odin",MODE_PRIVATE).getString("lastGameUrl","");
  // Direkt in die Welt: /page/play/<welt> fuehrt nach der Anmeldung dorthin.
  String ziel = !welt.isEmpty() ? "https://www.die-staemme.de/page/play/"+welt
              : (lastGame.contains("die-staemme.de") ? lastGame : "https://www.die-staemme.de/");
  webView.loadUrl(ziel);}
 private android.view.View buildHeader(String activeName){
  LinearLayout bar=new LinearLayout(this); bar.setOrientation(LinearLayout.HORIZONTAL);
  bar.setBackgroundColor(0xFF2B2B2B); bar.setPadding(24,18,12,18); bar.setGravity(android.view.Gravity.CENTER_VERTICAL);
  LinearLayout col=new LinearLayout(this); col.setOrientation(LinearLayout.VERTICAL);
  final TextView t=new TextView(this);
  t.setText((activeName.isEmpty()?"Die Stämme":activeName)+" ⌄");
  t.setTextColor(0xFFFFFFFF); t.setTextSize(16f); t.setSingleLine(true);
  col.addView(t);
  statusView=new TextView(this); statusView.setText("APK "+apkVersion()+" · GodBot: wartet"); statusView.setTextColor(0xFFBBBBBB);
  statusView.setTextSize(11f); statusView.setSingleLine(true);
  // Tippen kopiert das komplette Protokoll in die Zwischenablage.
  statusView.setOnClickListener(x->protokollZeigen());
  statusView.setOnLongClickListener(x->{copyStatusLog();return true;});
  // Einklappbar, Zustand wird gemerkt.
  boolean offen=getSharedPreferences("odin",MODE_PRIVATE).getBoolean("statusOffen",true);
  statusView.setVisibility(offen?android.view.View.VISIBLE:android.view.View.GONE);
  col.addView(statusView);
  t.setOnClickListener(x->{
   boolean sichtbar=statusView.getVisibility()==android.view.View.VISIBLE;
   statusView.setVisibility(sichtbar?android.view.View.GONE:android.view.View.VISIBLE);
   getSharedPreferences("odin",MODE_PRIVATE).edit().putBoolean("statusOffen",!sichtbar).apply();
  });
  bar.addView(col,new LinearLayout.LayoutParams(0,-2,1f));
  Button back=new Button(this); back.setText("Dashboard"); back.setTextSize(12f); back.setAllCaps(false);
  // Frueher finish(): damit war die Spielansicht weg und das Spiel startete
  // beim Zurueckkehren von vorn. Jetzt bleibt sie im Stapel bestehen.
  back.setOnClickListener(x->{
   Intent i=new Intent(this,MainActivity.class);
   i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
   startActivity(i);
  });
  bar.addView(back,new LinearLayout.LayoutParams(-2,-2));
  // Testalarm-Knopf (⏱) entfernt - der Wecker ist erprobt.
  Button dim=new Button(this); dim.setText("🌙"); dim.setTextSize(12f); dim.setAllCaps(false);
  dim.setPadding(10,0,10,0);
  dim.setOnClickListener(x->dimmenAn());
  bar.addView(dim,new LinearLayout.LayoutParams(-2,-2));
  leaseKnopf=new Button(this); leaseKnopf.setText("Übernehmen"); leaseKnopf.setTextSize(12f); leaseKnopf.setAllCaps(false);
  leaseKnopf.setVisibility(android.view.View.GONE);
  leaseKnopf.setOnClickListener(x->{
   final String k=gameAccountId; final Context app=getApplicationContext();
   setStatus("Übernehme GodBot von dem anderen Gerät ...");
   new Thread(()->{
    Object[] e=OdinService.leaseHolen(app,k,true);
    if(e!=null&&(Boolean)e[0]){ OdinService.WARTET.remove(k); neuLadenFuer(k,"GodBot übernommen - das andere Gerät pausiert bei seiner nächsten Prüfung"); }
    else setStatus("Übernehmen fehlgeschlagen - keine Verbindung?");
   }).start();
  });
  bar.addView(leaseKnopf,new LinearLayout.LayoutParams(-2,-2));
  Button min=new Button(this); min.setText("Minimieren"); min.setTextSize(12f); min.setAllCaps(false);
  min.setOnClickListener(x->{
   if(!OdinBubble.allowed(this)){
    setStatus("Bitte 'Über anderen Apps anzeigen' erlauben");
    OdinBubble.requestPermission(this); return;
   }
   // Die WebView wandert in ein sichtbares Overlay. Nur so bleiben die
   // JS-Zeitgeber ungedrosselt - ein blosses moveTaskToBack() macht sie
   // unsichtbar und Chromium taktet sie auf etwa einmal pro Minute herunter.
   if(OdinFloat.show(this,gameAccountId,webView,this::restoreFromFloat)){
    setStatus("schwebt ("+OdinFloat.anzahl()+" aktiv) – Symbol antippen");
    moveTaskToBack(true);
   }else{
    OdinBubble.setReturnTarget(GameWebViewActivity.class,gameAccountId);
    OdinBubble.show(this);
    setStatus("minimiert (gedrosselt)");
    moveTaskToBack(true);
   }
  });
  bar.addView(min,new LinearLayout.LayoutParams(-2,-2));
  // Kopf = Titelleiste + GodBot-Leiste. Als EIN Kind der Wurzel, damit die
  // WebView weiter an Position 1 steht (holeAusFenster setzt sie dort ein).
  LinearLayout kopf=new LinearLayout(this); kopf.setOrientation(LinearLayout.VERTICAL);
  kopf.addView(bar,new LinearLayout.LayoutParams(-1,-2));
  kopf.addView(buildGodBotLeiste(),new LinearLayout.LayoutParams(-1,-2));
  return kopf;
 }
 // --- GodBot-Leiste (1.79.0) ------------------------------------------------
 // GodBot gehoert zur App. Sein Zustand steht hier nativ unter der
 // Kopfzeile statt als schwebendes Kaestchen in der Spielseite. Bedienung
 // wie bei den Kacheln im Spiel: Tippen oeffnet den Bereich, langer Druck
 // schaltet ihn an oder aus. GodBot liefert den Stand selbst (Odin.stand),
 // alle 5 s und bei jeder Aenderung - die Leiste fragt nie nach.
 private HorizontalScrollView godbotLeiste;
 private final java.util.Map<String,TextView> godbotChips=new java.util.LinkedHashMap<>();
 private org.json.JSONObject godbotStand=null;
 private boolean godbotTickerAn=false;
 // Schluessel, Beschriftung, Name der Prozesssperre in GodBot (laeuft gerade)
 private static final String[][] GODBOT_BEREICHE={
  {"raubzug","Raubzug","scavenge"},{"farmen","Farmen","farm"},{"bau","Manager","bau"},
  {"rohstoffe","Rohstoffe","resources"},{"angriffe","Angriffe","attack"},
  {"rausstellen","Rausstellen","rausstellen"},{"statistik","Statistik",""},{"godbot","GodBot ⋯",""}};
 private static boolean godbotSchaltbar(String k){
  return "raubzug".equals(k)||"farmen".equals(k)||"bau".equals(k)||"rohstoffe".equals(k);
 }
 private android.graphics.drawable.GradientDrawable godbotChipGrund(int farbe,int rand){
  android.graphics.drawable.GradientDrawable g=new android.graphics.drawable.GradientDrawable();
  g.setCornerRadius(60f); g.setColor(farbe); g.setStroke(2,rand); return g;
 }
 private android.view.View buildGodBotLeiste(){
  HorizontalScrollView sc=new HorizontalScrollView(this);
  sc.setHorizontalScrollBarEnabled(false); sc.setBackgroundColor(0xFF1E2430);
  LinearLayout row=new LinearLayout(this); row.setOrientation(LinearLayout.HORIZONTAL);
  row.setPadding(18,10,18,10); row.setGravity(android.view.Gravity.CENTER_VERTICAL);
  for(String[] b:GODBOT_BEREICHE){
   final String key=b[0];
   TextView c=new TextView(this); c.setText(b[1]); c.setTextSize(12f); c.setTextColor(0xFFC9D4E3);
   c.setSingleLine(true); c.setPadding(26,11,26,11);
   c.setBackground(godbotChipGrund(0xFF2A3342,0xFF3A4556));
   LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-2,-2); lp.rightMargin=12; c.setLayoutParams(lp);
   c.setOnClickListener(x->godbotJs("GodBotSteuerung.oeffnen('"+key+"')&&''",null));
   c.setOnLongClickListener(x->{
    if(!godbotSchaltbar(key))return false;
    x.performHapticFeedback(android.view.HapticFeedbackConstants.LONG_PRESS);
    godbotJs("(function(){var r=GodBotSteuerung.umschalten('"+key+"');return (r&&r.ok?'':'nicht geschaltet: ')+((r&&r.text)||'')})()",
     r->{ try{ Object o=new org.json.JSONTokener(r).nextValue(); if(o instanceof String)setStatus("GodBot: "+o); }catch(Exception ignored){} });
    return true;
   });
   godbotChips.put(key,c); row.addView(c);
  }
  sc.addView(row);
  // Erst zeigen, wenn GodBot sich gemeldet hat - ohne GodBot (Geraete-
  // Sperre, Zugangssperre) waere die Leiste eine leere Behauptung.
  sc.setVisibility(android.view.View.GONE);
  godbotLeiste=sc;
  return sc;
 }
 private void godbotJs(String ausdruck,ValueCallback<String> cb){
  final WebView w=webView; if(w==null)return;
  final String js="(function(){try{if(!window.GodBotSteuerung)return null;return "+ausdruck+"}catch(e){return null}})()";
  runOnUiThread(()->{ try{ w.evaluateJavascript(js,cb); }catch(Exception ignored){} });
 }
 private void godbotStandEmpfangen(String json){
  try{ godbotStand=new org.json.JSONObject(json); }catch(Exception e){ return; }
  runOnUiThread(()->{
   if(godbotLeiste!=null&&godbotLeiste.getVisibility()!=android.view.View.VISIBLE)
    godbotLeiste.setVisibility(android.view.View.VISIBLE);
   godbotLeisteZeichnen();
   if(!godbotTickerAn&&godbotLeiste!=null){ godbotTickerAn=true; godbotTicker(); }
  });
 }
 // Restzeiten laufen nativ weiter, auch wenn GodBot gerade gedrosselt ist.
 private void godbotTicker(){
  if(godbotLeiste==null||isFinishing()){ godbotTickerAn=false; return; }
  godbotLeiste.postDelayed(()->{ godbotLeisteZeichnen(); godbotTicker(); },15000L);
 }
 private void godbotLeisteZeichnen(){
  org.json.JSONObject st=godbotStand; if(st==null)return;
  org.json.JSONObject sch=st.optJSONObject("schalter"), nx=st.optJSONObject("naechst"), pr=st.optJSONObject("probleme");
  String laeuft=st.optString("laeuft","");
  boolean bot=st.optBoolean("botschutz",false), hub=st.optBoolean("hubOffen",false);
  long jetzt=System.currentTimeMillis();
  // Seit ueber 30 s nichts gehoert: GodBot schlaeft (gedrosselt, Seite
  // laedt). Der Stand bleibt stehen, wirkt aber zurueckgenommen.
  boolean frisch=jetzt-st.optLong("at",0)<30000L;
  for(String[] b:GODBOT_BEREICHE){
   TextView c=godbotChips.get(b[0]); if(c==null)continue;
   String name=b[1]; int punkt=0, grund=0xFF2A3342, rand=0xFF3A4556, schrift=0xFFC9D4E3; String zusatz="";
   boolean istLauf=!b[2].isEmpty()&&b[2].equals(laeuft);
   // Problem wie das rote "!" der Kachel im Spiel (Vorlage fehlt, kein
   // Premium, ...). Steht ueber "an" - sonst wirkt alles in Ordnung.
   String problem=pr!=null?pr.optString(b[0],""):"";
   if(!bot&&!istLauf&&!problem.isEmpty()){
    punkt=0xFFE8734A; zusatz=" · Problem"; rand=0xFF8A4A2E; grund=0xFF33241E; schrift=0xFFF0D2C4;
   } else
   if(godbotSchaltbar(b[0])&&sch!=null&&sch.has(b[0])){
    boolean an=sch.optBoolean(b[0],false);
    if(bot&&an){ punkt=0xFFE05555; zusatz=" · Botschutz"; rand=0xFF7A2E2E; }
    else if(istLauf){ punkt=0xFFFFD24A; zusatz=" · läuft"; rand=0xFF8A7430; grund=0xFF332D1E; }
    else if(an){
     punkt=0xFF4CC38A; rand=0xFF2F6B52; grund=0xFF1F3129;
     long t=nx!=null?nx.optLong(b[0],0):0;
     if(t>0){ long m=(t-jetzt)/60000L; zusatz=t<=jetzt?" · fällig":(m<1?" · <1 Min":" · "+m+" Min"); }
    } else { punkt=0xFF5B6678; schrift=0xFF8A96A8; }
   } else if(istLauf){ punkt=0xFFFFD24A; zusatz=" · läuft"; rand=0xFF8A7430; grund=0xFF332D1E; }
   else if("godbot".equals(b[0])&&hub){ grund=0xFF3A3222; rand=0xFFB8893F; schrift=0xFFEAD7B0; }
   android.text.SpannableStringBuilder t=new android.text.SpannableStringBuilder();
   if(punkt!=0){ t.append("● "); t.setSpan(new android.text.style.ForegroundColorSpan(punkt),0,1,0); }
   t.append(name).append(zusatz);
   c.setText(t); c.setTextColor(schrift); c.setBackground(godbotChipGrund(grund,rand));
   c.setAlpha(frisch?1f:0.6f);
  }
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
    String welt=o.optString("world","");
    boolean active=nm.equals(activeName);
    TextView c=new TextView(this);
    c.setText(welt.isEmpty()?nm:(nm+"  ·  "+welt));
    c.setTextSize(12f); c.setPadding(22,10,22,10);
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
 private static String nz(String x){ return x==null?"":x; }
 // Leises Wecken: die Seite muss sichtbar sein, damit die Zeitgeber laufen -
 // aber nicht im Vordergrund. Benutzt du das Geraet gerade, wandert die
 // Ansicht ins schwebende Symbol statt dir dazwischenzufunken.
 // Rueckgabe false heisst: keine Ansicht vorhanden, der Dienst muss sie
 // regulaer starten.
 static boolean weckeLeise(String accountId){
  GameWebViewActivity a=OFFEN.get(accountId==null?"":accountId);
  if(a==null||a.isFinishing())return false;
  a.runOnUiThread(a::leiseSchweben);
  return true;
 }
 // Laeuft auf der Oberflaechenschleife der eigenen Ansicht - dadurch keine
 // Zugriffe auf Felder einer fremden Instanz.
 private Runnable leiseWaechter=null;
 // Das kleine Fenster schliesst sich selbst, sobald der Durchlauf fertig ist.
 // Erkannt am ausbleibenden Puls: GodBot schreibt bei jedem Arbeitsschritt in
 // den localStorage. Danach ist die Ansicht bis zum naechsten Termin
 // gedrosselt - bei einem Raubzug alle zwanzig Minuten vertretbar und
 // deutlich sparsamer.
 private void leiseSchliessenNachArbeit(){
  final long start=System.currentTimeMillis();
  letzteAktivitaet=start;
  if(leiseWaechter!=null)getWindow().getDecorView().removeCallbacks(leiseWaechter);
  leiseWaechter=new Runnable(){
   @Override public void run(){
    if(!OdinFloat.active(gameAccountId))return;   // von Hand zurueckgeholt
    long jetzt=System.currentTimeMillis();
    long lief=jetzt-start, still=jetzt-letzteAktivitaet;
    if(lief>FENSTER_MAX_MS){ setStatus("Fenster: Höchstdauer erreicht"); holeAusFenster(false); return; }
    if(lief>FENSTER_MIN_MS&&still>RUHE_MS){
     setStatus("Fenster: fertig nach "+(lief/1000)+" s"); holeAusFenster(false); return;
    }
    getWindow().getDecorView().postDelayed(this,10_000L);
   }
  };
  getWindow().getDecorView().postDelayed(leiseWaechter,10_000L);
 }
 private void leiseSchweben(){
  try{
   // Im Dimm-Modus ist die WebView bereits sichtbar und ungedrosselt. Das
   // kleine Fenster wuerde sie aus der gedimmten Ansicht herausreissen und
   // nach getaner Arbeit in die dann im Hintergrund liegende Activity
   // zurueckhaengen - genau so brach die Nachtaktivitaet ab.
   if(dimDecke!=null){ setStatus("Termin - Dimm-Modus läuft, nichts nötig"); return; }
   // Und genauso, wenn die Ansicht einfach offen vor einem liegt: dann ist
   // die WebView schon gerendert und ungedrosselt. Das kleine Fenster riss
   // sie aus der offenen Ansicht heraus und haengte sie danach zurueck -
   // fuer den Benutzer ein Mini-Fenster, das ueber der laufenden App
   // aufpoppt, obwohl er direkt davor sitzt.
   if(imVordergrund){ setStatus("Termin - Ansicht ist offen, nichts nötig"); return; }
   if(webView==null){ setStatus("Termin - keine Ansicht vorhanden"); return; }
   if(OdinFloat.active(gameAccountId)){ setStatus("Termin - schwebt bereits"); return; }
   // Bewusst das kleine Fenster: fuer die Aktion reicht, dass die WebView
   // gerendert wird. Groesse spielt fuer die Drosselung keine Rolle.
   if(OdinFloat.show(this,gameAccountId,webView,this::restoreFromFloat,OdinFloat.KLEIN)){
    setStatus("Termin - kleines Fenster, Gerät nicht gestört");
    leiseSchliessenNachArbeit();
   }
   else
    setStatus("Termin - Symbol nicht möglich");
  }catch(Exception e){ Log.w("ODIN_GODBOT","leiseSchweben",e); }
 }
 // In der Datenbank steht die Welt oft nur als Zahl ("256"). Die Spielseite
 // erwartet aber den vollen Namen ("de256") - /page/play/256 antwortet mit
 // "invalid data". Deshalb hier vereinheitlichen statt saubere Eingaben
 // vorauszusetzen.
 static String normWelt(String w){
  if(w==null)return "";
  String x=w.trim().toLowerCase().replace("welt","").replace(" ","");
  if(x.isEmpty())return "";
  if(x.matches("[0-9]+"))return "de"+x;          // 256   -> de256
  if(x.matches("[a-z]{2,3}[0-9]+"))return x;     // de256 -> de256
  return x;
 }
 // Trennt Cookies und Speicher je Spielaccount. Ohne das teilen sich alle
 // Ansichten eine Sitzung: Anmeldung mit Konto B oeffnete das Spiel von A.
 private void profilSetzen(WebView v,String accountId){
  if(accountId==null||accountId.isEmpty())return;
  try{
   if(androidx.webkit.WebViewFeature.isFeatureSupported(androidx.webkit.WebViewFeature.MULTI_PROFILE)){
    String name=OdinVault.profilName(this,accountId);
    androidx.webkit.ProfileStore.getInstance().getOrCreateProfile(name);
    androidx.webkit.WebViewCompat.setProfile(v,name);
    setStatus("Profil "+name);
   }else{
    // Aeltere WebView-Versionen koennen das nicht - dann bleibt es bei einer
    // gemeinsamen Sitzung, und das sagen wir auch statt es zu verschweigen.
    setStatus("Achtung: WebView zu alt für getrennte Konten");
   }
  }catch(Exception e){ setStatus("Profil fehlgeschlagen: "+e.getMessage()); }
 }
 // Vom Wecker gestartet: ueber dem Sperrbildschirm anzeigen und den Schirm
 // einschalten. Erst dadurch wird die WebView sichtbar und laeuft ungedrosselt.
 // Vollbild bleibt bestehen, nur die Anzeige wird dunkel. Entscheidend: die
 // WebView wird weiter GERENDERT - die Abdeckung liegt nur davor. Ein
 // Minimieren wuerde sie unsichtbar machen und Chromium drosselt dann die
 // Zeitgeber; hier laeuft alles im vollen Takt weiter.
 // Die Skriptliste gehoert dem Team und wird im Dashboard gepflegt. Gelingt
 // der Abruf, ersetzt sie die oertliche Fassung; die bleibt nur Notvorrat,
 // damit ein Start ohne Netz nicht ganz ohne Skripte endet.
 private org.json.JSONArray serverSkripte(){
  try{
   if(skriptListe!=null&&System.currentTimeMillis()-skriptListeZeit<5L*60L*1000L)return skriptListe;
   if(supaUrl.isEmpty()||supaToken.isEmpty()||supaTeam.isEmpty())return null;
   String r=supaRequest("GET","scripts?select=id,name,type,source_url,code,enabled"
     +"&team_id=eq."+supaTeam+"&order=created_at.asc",null);
   org.json.JSONArray sv=new org.json.JSONArray(r);
   org.json.JSONArray out=new org.json.JSONArray();
   for(int i=0;i<sv.length();i++){
    org.json.JSONObject o=sv.optJSONObject(i); if(o==null)continue;
    String code=o.isNull("code")?"":o.optString("code","");
    String url=o.optString("source_url","");
    // Der alte Gist-Eintrag fuer GodBot bleibt aussen vor: GodBot ist
    // eingebaut und darf nicht ein zweites Mal laufen.
    if(OdinSkripte.istGodBotEintrag("",url))continue;
    org.json.JSONObject z=new org.json.JSONObject();
    z.put("id",o.optString("id",""));
    z.put("name",o.optString("name","(ohne Namen)"));
    z.put("an",o.optBoolean("enabled",false));
    if(!code.trim().isEmpty()){ z.put("quelle","code"); z.put("code",code); }
    else { z.put("quelle","url"); z.put("url",url); }
    out.put(z);
   }
   OdinSkripte.speichern(this,out);
   skriptListe=out; skriptListeZeit=System.currentTimeMillis();
   return out;
  }catch(Exception e){ setStatus("Skriptliste vom Server nicht erreichbar"); return null; }
 }
 // Ein neues @version melden und im Dashboard sichtbar machen. Ohne das
 // laeuft eine neue Fassung still an und niemand weiss, ob sie ankam.
 private void versionPruefen(String id,String name,String quelltext){
  try{
   String v=OdinSkripte.versionAus(quelltext);
   if(v.isEmpty())return;
   String alt=OdinSkripte.letzteVersion(this,id);
   if(v.equals(alt))return;
   OdinSkripte.merkeVersion(this,id,v);
   String text=alt.isEmpty()? (name+" v"+v+" geladen")
                            : (name+": v"+alt+" → v"+v);
   setStatus(text);
   OdinService.protokoll(this,"WICHTIG","skripte",text);
   if(!alt.isEmpty()){ try{ new OdinNative().notify("Skript aktualisiert",text,"info"); }catch(Exception ignored){} }
   // Nur echte Tabelleneintraege haben eine UUID; der oertliche Notvorrat nicht.
   if(!supaTeam.isEmpty()&&id.length()==36)
    try{ supaRequest("PATCH","scripts?id=eq."+id,"{\"version\":"+org.json.JSONObject.quote(v)+"}"); }
    catch(Exception ignored){}
  }catch(Exception ignored){}
 }
 private void dimmenAn(){
  if(dimRahmen==null)return;
  // Immer zuerst die Fensterflaggen: auch beim Auffrischen durch den Dienst
  // muessen sie wieder stehen, sonst faellt die Ansicht hinter den
  // Sperrbildschirm und wird nicht mehr gerendert.
  dimmFlaggen();
  try{ getSharedPreferences("odin_svc",MODE_PRIVATE).edit()
        .putBoolean("dimm_an",true).putString("dimm_konto",nz(gameAccountId)).apply(); }
  catch(Exception ignored){}
  if(dimDecke!=null){ setStatus("Dimm-Modus aufgefrischt"); return; }
  if(webView!=null){ webView.removeCallbacks(dimmPuls); webView.postDelayed(dimmPuls,300_000L); }
  android.widget.LinearLayout decke=new android.widget.LinearLayout(this);
  decke.setOrientation(android.widget.LinearLayout.VERTICAL);
  decke.setGravity(android.view.Gravity.CENTER);
  decke.setBackgroundColor(0xFF000000);
  OdinMark zeichen=new OdinMark(this);
  int gr=(int)(getResources().getDisplayMetrics().density*150);
  decke.addView(zeichen,new android.widget.LinearLayout.LayoutParams(gr,gr));
  dimZeichen=zeichen;
  TextView hin=new TextView(this);
  hin.setText("ODIN LÄUFT\n\nBildschirm ist an, nur gedimmt\nZum Beenden nach rechts wischen");
  // Deutlich sichtbar: bei Helligkeit 0 wirkt selbst helles Grau gedaempft,
  // ein dunkler Hinweis dagegen wie ein ausgeschalteter Bildschirm.
  // Dezenter als das Zeichen: der Valknut traegt, die Schrift erklaert nur.
  hin.setTextColor(0xFF7C7C7C); hin.setTextSize(13f);
  hin.setLetterSpacing(0.08f);
  hin.setLineSpacing(0f,1.4f);
  hin.setPadding(0,(int)(getResources().getDisplayMetrics().density*20),0,0);
  hin.setGravity(android.view.Gravity.CENTER);
  decke.addView(hin);
  dimHinweis=hin;
  // Kein Tippen mehr: in der Hosentasche reicht der kleinste Kontakt, und
  // der Dimm-Modus waere weg - samt laufender Nachtarbeit. Nur eine
  // bewusste waagerechte Wischbewegung beendet ihn. Dieselbe Geste und
  // dieselben Schwellen wie GodBots Hosentaschen-Schutz.
  decke.setOnTouchListener(this::dimBeruehrung);
  dimRahmen.addView(decke,new FrameLayout.LayoutParams(-1,-1));
  dimDecke=decke;
  // Kurz zeigen, was da liegt, dann in die Ruhe fallen - sonst waere der
  // Umschaltmoment nicht von einem Absturz zu unterscheiden.
  dimWach(); dimNachdunkeln();
  setStatus("gedimmt - läuft im vollen Takt weiter");
 }
 // Alles, was den Bildschirm an und die Ansicht vorn haelt - auch ueber dem
 // Sperrbildschirm. setShowWhenLocked ENTSPERRT nichts: das Geraet bleibt
 // gesperrt, die Ansicht liegt nur davor und wird dadurch weiter gerendert.
 private void dimmFlaggen(){
  android.view.Window w=getWindow();
  android.view.WindowManager.LayoutParams lp=w.getAttributes();
  // Ruhe heisst wirklich dunkel: Helligkeit 0 und die Abdeckung unsichtbar.
  // Zu sehen sein soll nur, wer den Bildschirm beruehrt.
  lp.screenBrightness=DIM_RUHE; w.setAttributes(lp);
  w.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(true); setTurnScreenOn(true); }
  w.addFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
            |android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
  vollbildUnterdruecken=false;
  Fullscreen.apply(this);
 }
 // Schwellen wie in GodBot: bei 412 px Breite genau 140 px Wischweg und
 // hoechstens 70 px senkrechte Abweichung. An der Bildschirmbreite
 // aufgehaengt, damit sie auf jedem Geraet dasselbe bedeuten.
 private static final long DIM_WISCH_MIN_MS=120L, DIM_WISCH_MAX_MS=2500L, DIM_ZURUECK_MS=5000L;
 // Ruhe: Helligkeit 0, Inhalt unsichtbar - vom ausgeschalteten Bildschirm
 // nicht zu unterscheiden. Wach: nur solange jemand hinschaut.
 private static final float DIM_RUHE=0f, DIM_WACH=0.15f;
 private android.widget.TextView dimHinweis;
 private android.view.View dimZeichen;
 private void dimHelligkeit(float f){
  try{
   android.view.Window w=getWindow();
   android.view.WindowManager.LayoutParams lp=w.getAttributes();
   lp.screenBrightness=f; w.setAttributes(lp);
  }catch(Exception ignored){}
 }
 // Sichtbarkeit ueber die Deckkraft, nicht ueber GONE: das Bild bleibt
 // gerendert, und nur darauf beruht der volle Takt der WebView.
 private void dimSicht(float a){
  if(dimZeichen!=null)dimZeichen.setAlpha(a);
  if(dimHinweis!=null)dimHinweis.setAlpha(a);
 }
 private void dimRuhe(){ dimHelligkeit(DIM_RUHE); dimSicht(0f); }
 private void dimWach(){ dimHelligkeit(DIM_WACH); dimSicht(1f); }
 private float dimStartX, dimStartY; private long dimStartT;
 private Runnable dimZurueck=null;
 // setTurnScreenOn/FLAG_TURN_SCREEN_ON wirken nur, wenn die Activity
 // fortgesetzt wird. Ist der Bildschirm aus, kommt es dazu aber nicht - die
 // Rueckholung des Dienstes lief am 23.09. 02:45-03:00 alle 2 Minuten ins
 // Leere. Ein kurzer Wecklock schaltet den Bildschirm ein; danach halten die
 // Dimm-Flaggen ihn an (Helligkeit 0).
 @SuppressWarnings("deprecation")
 private void bildschirmEin(){
  try{
   android.os.PowerManager pm=(android.os.PowerManager)getSystemService(POWER_SERVICE);
   if(pm==null||pm.isInteractive())return;
   android.os.PowerManager.WakeLock wl=pm.newWakeLock(
     android.os.PowerManager.SCREEN_DIM_WAKE_LOCK|android.os.PowerManager.ACQUIRE_CAUSES_WAKEUP,"odin:dimm");
   wl.acquire(5000L);
   setStatus("Dimm-Modus: Bildschirm eingeschaltet");
  }catch(Exception e){ setStatus("Dimm-Modus: Bildschirm einschalten fehlgeschlagen: "+e.getMessage()); }
 }
 // Nachschau 5 s spaeter: ist die Ansicht wirklich vorn, ist der Bildschirm
 // an und haelt Chromium die Seite fuer sichtbar? Bisher meldete der Dienst
 // nur den Startversuch ("wiederhergestellt"), nie ob er ankam.
 // anlass==null: stiller Puls, meldet nur Abweichungen.
 private void dimmKontrolle(final String anlass){
  if(webView==null)return;
  webView.postDelayed(()->{
   try{
    if(dimDecke==null||webView==null)return;
    android.os.PowerManager pm=(android.os.PowerManager)getSystemService(POWER_SERVICE);
    final boolean an=pm!=null&&pm.isInteractive();
    final boolean vorn=imVordergrund;
    final String wer=anlass==null?"Puls":anlass;
    final boolean[] antwort={false};
    webView.evaluateJavascript("document.visibilityState",r->{
     antwort[0]=true;
     boolean sichtbar=r!=null&&r.contains("visible");
     if(anlass!=null||!vorn||!an||!sichtbar)
      setStatus("Dimm-Kontrolle ("+wer+"): "+(vorn&&an&&sichtbar?"OK":"GESTOERT")
        +" - vorn="+vorn+", Bildschirm="+(an?"an":"aus")+", Seite="+r);
    });
    webView.postDelayed(()->{
     if(!antwort[0])setStatus("Dimm-Kontrolle ("+wer+"): GESTOERT - vorn="+vorn
       +", Bildschirm="+(an?"an":"aus")+", Seite antwortet nicht");
    },3000);
   }catch(Exception ignored){}
  },5000);
 }
 // Alle 10 Minuten still nachsehen, solange gedimmt ist.
 private long dimmNeuGeladen=0L;
 // --- Anfragen an den Spielserver zaehlen ---------------------------------
 // Nur beobachten, nie veraendern. Erfasst ALLES, was die Spielansicht an
 // game.php schickt - Seitenaufrufe, Hintergrundrahmen, fetch/XHR -, egal
 // ob von GodBot, einem Zusatzskript oder dem Spiel selbst. Alle 10 Minuten
 // eine Zeile ins Protokoll (landet auch in app_events, bereich "app"):
 //   Spielserver 10 Min: 42 Anfragen, 9 Seitenaufrufe - am_farm 12, ...
 // Grundlage, um unnoetige Anfragen mit Zahlen statt Vermutungen zu finden.
 private final java.util.HashMap<String,Integer> anfragen=new java.util.HashMap<>();
 private long anfragenSeit=0L; private int anfragenGesamt=0, anfragenSeiten=0;
 private void anfrageZaehlen(WebResourceRequest r){
  try{
   android.net.Uri u=r.getUrl(); String h=u.getHost();
   if(h==null||!h.endsWith("die-staemme.de"))return;
   String pfad=u.getPath(); if(pfad==null||!pfad.endsWith("/game.php"))return;
   String sc=u.getQueryParameter("screen"), mo=u.getQueryParameter("mode");
   String aj=u.getQueryParameter("ajaxaction"); if(aj==null)aj=u.getQueryParameter("ajax");
   if(aj==null)aj=u.getQueryParameter("action");
   boolean seite=r.isForMainFrame();
   String k=(sc==null?"?":sc)+(mo!=null?"/"+mo:"")+(aj!=null?":"+aj:"")+(seite?"*":"");
   long jetzt=System.currentTimeMillis(); String bericht=null;
   synchronized(anfragen){
    if(anfragenSeit==0L)anfragenSeit=jetzt;
    Integer n=anfragen.get(k); anfragen.put(k,n==null?1:n+1);
    anfragenGesamt++; if(seite)anfragenSeiten++;
    if(jetzt-anfragenSeit>=600_000L){
     java.util.List<java.util.Map.Entry<String,Integer>> l=new java.util.ArrayList<>(anfragen.entrySet());
     java.util.Collections.sort(l,(x,y)->y.getValue()-x.getValue());
     StringBuilder b=new StringBuilder("Spielserver ").append((jetzt-anfragenSeit)/60000).append(" Min: ")
       .append(anfragenGesamt).append(" Anfragen, ").append(anfragenSeiten).append(" Seitenaufrufe - ");
     for(int i=0;i<l.size()&&i<10;i++){ if(i>0)b.append(", "); b.append(l.get(i).getKey()).append(' ').append(l.get(i).getValue()); }
     bericht=b.toString();
     anfragen.clear(); anfragenSeit=jetzt; anfragenGesamt=0; anfragenSeiten=0;
    }
   }
   if(bericht!=null)setStatus(bericht);
  }catch(Exception ignored){}
 }
 private final Runnable dimmPuls=new Runnable(){ @Override public void run(){
  if(dimDecke==null||webView==null)return;
  dimmKontrolle(null);
  // Vorn, gedimmt - aber GodBot schweigt? Am 23.09. von 03:00 bis 07:30 kein
  // einziges Lebenszeichen. Dann die Seite neu laden (hoechstens alle 15 Min).
  long jetzt=System.currentTimeMillis(), l=OdinService.zuletztLebend(gameAccountId);
  if(imVordergrund&&!OdinService.gesperrt(gameAccountId)&&l>0&&jetzt-l>300_000L&&jetzt-dimmNeuGeladen>900_000L){
   dimmNeuGeladen=jetzt;
   setStatus("Dimm-Kontrolle: GodBot seit "+((jetzt-l)/60000)+" Min ohne Lebenszeichen - lade Seite neu");
   try{ webView.reload(); }catch(Exception ignored){}
  }
  webView.postDelayed(this,300_000L);
 }};
 private int dimBreite(){
  int b=getResources().getDisplayMetrics().widthPixels;
  return (b>=200&&b<=4000)?b:412;
 }
 private int dimWischMinX(){ return Math.round(dimBreite()*(140f/412f)); }
 private int dimWischMaxY(){ return Math.round(dimBreite()*(70f/412f)); }
 private void dimText(String t){ if(dimHinweis!=null)dimHinweis.setText(t); }
 // Ohne Bestaetigung dunkelt es nach fuenf Sekunden wieder ganz ab. Eine
 // liegengebliebene Aufhellung waere sonst die ganze Nacht sichtbar.
 private void dimNachdunkeln(){
  android.view.View d=dimDecke; if(d==null)return;
  if(dimZurueck!=null)d.removeCallbacks(dimZurueck);
  dimZurueck=()->{
   if(dimDecke==null)return;
   dimText("ODIN LÄUFT\n\nBildschirm ist an, nur gedimmt\nZum Beenden nach rechts wischen");
   dimRuhe();
  };
  d.postDelayed(dimZurueck,DIM_ZURUECK_MS);
 }
 private boolean dimBeruehrung(android.view.View v,android.view.MotionEvent e){
  switch(e.getActionMasked()){
   case android.view.MotionEvent.ACTION_DOWN: {
    dimStartX=e.getRawX(); dimStartY=e.getRawY(); dimStartT=System.currentTimeMillis();
    // Beruehrung ist das einzige, was die Abdeckung sichtbar macht.
    dimWach();
    dimText("→ zum Beenden nach rechts wischen");
    dimNachdunkeln();
    return true;
   }
   case android.view.MotionEvent.ACTION_MOVE: {
    float dx=e.getRawX()-dimStartX, dy=Math.abs(e.getRawY()-dimStartY);
    long dt=System.currentTimeMillis()-dimStartT;
    if(dy>dimWischMaxY()||dt>DIM_WISCH_MAX_MS) dimText("✗ Wischbewegung verlassen");
    else if(dx>=dimWischMinX()) dimText("✓ loslassen zum Beenden");
    else dimText("→ weiter nach rechts ("+Math.round(Math.max(0,dx))+" von "+dimWischMinX()+")");
    return true;
   }
   case android.view.MotionEvent.ACTION_UP: {
    float dx=e.getRawX()-dimStartX, dy=Math.abs(e.getRawY()-dimStartY);
    long dt=System.currentTimeMillis()-dimStartT;
    int minX=dimWischMinX(), maxY=dimWischMaxY();
    // Wortlos abbrechen waere falsch: wer im Dunkeln wischt und nichts
    // passiert, kann nicht herausfinden warum.
    String grund = (dx<minX) ? "zu kurz ("+Math.round(dx)+" von "+minX+" px)"
                 : (dy>maxY) ? "zu schräg ("+Math.round(dy)+" von höchstens "+maxY+" px)"
                 : (dt<DIM_WISCH_MIN_MS) ? "zu schnell"
                 : (dt>DIM_WISCH_MAX_MS) ? "zu langsam" : null;
    if(grund==null){ dimmenAus(); return true; }
    dimText("✗ "+grund+"\nzum Beenden nach rechts wischen");
    dimNachdunkeln();
    return true;
   }
   case android.view.MotionEvent.ACTION_CANCEL: dimNachdunkeln(); return true;
  }
  return false;
 }
 private void dimmenAus(){
  dimZeichen=null;
  // Der Wunsch faellt IMMER weg, auch wenn gerade keine Abdeckung liegt -
  // sonst holt der Wächter des Dienstes den Dimm-Modus wieder zurueck.
  try{ getSharedPreferences("odin_svc",MODE_PRIVATE).edit()
        .putBoolean("dimm_an",false).apply(); }catch(Exception ignored){}
  if(dimDecke==null)return;
  if(dimZurueck!=null){ try{ dimDecke.removeCallbacks(dimZurueck); }catch(Exception ignored){} dimZurueck=null; }
  dimHinweis=null;
  try{ dimRahmen.removeView(dimDecke); }catch(Exception ignored){}
  dimDecke=null;
  android.view.Window w=getWindow();
  android.view.WindowManager.LayoutParams lp=w.getAttributes();
  lp.screenBrightness=android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
  w.setAttributes(lp);
  w.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  w.clearFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
              |android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
  if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(false); setTurnScreenOn(false); }
  setStatus("Anzeige normal");
 }
 private void weckerModus(){
  try{
   // Der Dienst kann den Dimm-Modus anfordern - auch ueber dem
   // Sperrbildschirm. Die Abdeckung setzt alle Fensterflaggen selbst.
   if(getIntent().getBooleanExtra("dimm",false)){
    // Die Sperrbildschirm-Flaggen SOFORT setzen, nicht erst wenn die
    // Abdeckung steht: sonst zeigt das Geraet fuer einen Moment den
    // Sperrbildschirm davor und die WebView wird nicht gerendert.
    if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(true); setTurnScreenOn(true); }
    getWindow().addFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                        |android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                        |android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
    // Direkt, nicht nachgereicht: die Flaggen muessen stehen, bevor Android
    // entscheidet, ob die Ansicht vor den Sperrbildschirm darf. Den
    // Bildschirm schaltet die Vollbild-Benachrichtigung ein - ein eigener
    // Wecklock vorher liess sie als blosse Kopfzeile erscheinen.
    dimmenAn();
    dimmKontrolle("Rückholung");
    return;
   }
   // Laeuft der Dimm-Modus, ist die Ansicht schon vorn, hell genug und
   // ungedrosselt. Der Weckermodus wuerde sie am Ende in den Hintergrund
   // schicken und damit den Dimm-Modus zerstoeren.
   if(dimDecke!=null){
    if(imVordergrund){ setStatus("Wecker: Dimm-Modus läuft vorn - unverändert"); return; }
    // Gedimmt, aber NICHT vorn (Bildschirm aus, Sperrbildschirm davor): die
    // Seite laeuft dann gedrosselt und erledigt den Termin nicht. Frueher
    // wurde hier trotzdem abgebrochen - so fielen am 23.09. Rohstoffe
    // (02:47) und Raubzug (03:00) aus.
    setStatus("Wecker: gedimmt, aber nicht vorn - hole zurück");
    if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(true); setTurnScreenOn(true); }
    dimmenAn();
    dimmKontrolle("Wecker");
    return;
   }
   if(!getIntent().getBooleanExtra("fromAlarm",false))return;
   android.view.Window w=getWindow();
   // Kein Vollbild beim Wecken: sonst ist nicht zu erkennen, ob das Geraet
   // noch gesperrt ist. Die Systemleisten bleiben sichtbar.
   vollbildUnterdruecken=true;
   systemleistenZeigen();
   if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(true); setTurnScreenOn(true); }
   else w.addFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                  |android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
   w.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
   // Der Bildschirm MUSS an sein, sonst rendert Chromium die WebView nicht
   // und die Zeitgeber bleiben gedrosselt. Er darf aber dunkel sein:
   // Helligkeit 0 ist die niedrigste Stufe, nicht "aus".
   android.view.WindowManager.LayoutParams lp=w.getAttributes();
   // Nicht ganz auf 0: beim Wecken soll erkennbar bleiben, dass der
   // Bildschirm an ist - sonst tippt man im Dunkeln daneben.
   lp.screenBrightness=0.03f; w.setAttributes(lp);
   dunkelWegenWecker=true;
   // Bei gesichertem Sperrbildschirm NICHT requestDismissKeyguard aufrufen:
   // das entsperrt nichts, sondern blendet die PIN-/Musterabfrage ein - und
   // die legt sich ueber die WebView. setShowWhenLocked zeigt die Ansicht
   // ohnehin ueber dem Sperrbildschirm an, gerendert und damit ungedrosselt.
   // Das Geraet bleibt dabei gesperrt.
   boolean gesichert=false;
   try{ android.app.KeyguardManager km=getSystemService(android.app.KeyguardManager.class);
        if(km!=null){
         gesichert=km.isKeyguardSecure();
         if(!gesichert&&Build.VERSION.SDK_INT>=26)km.requestDismissKeyguard(this,null);
        } }catch(Exception ignored){}
   setStatus(gesichert?"Wecker: über Sperrbildschirm, dunkel"
                     :"Wecker: Vordergrund, Anzeige dunkel");
   // Nur so lange offen, wie fuer die Aktion noetig. Danach zurueck in den
   // Hintergrund, damit das Geraet nachts nicht dauerhaft wach bleibt.
   // War der Account minimiert, liegt seine WebView im Overlay und NICHT in
   // dieser Activity. Ohne Rueckholen waere die Ansicht leer und der Termin
   // liefe ins Leere.
   weckBeginn=System.currentTimeMillis();
   warGeschwebt=OdinFloat.active(gameAccountId);
   if(warGeschwebt){ restoreFromFloat(); setStatus("Wecker: aus dem Symbol zurückgeholt"); }
   if(weckFensterEnde!=null)w.getDecorView().removeCallbacks(weckFensterEnde);
   if(ruhePruefer!=null)w.getDecorView().removeCallbacks(ruhePruefer);
   final long start=System.currentTimeMillis();
   letzteAktivitaet=start;
   final boolean wartung=getIntent().getBooleanExtra("wartung",false);
   ruhePruefer=new Runnable(){
    @Override public void run(){
     if(!weckerAktiv)return;
     long jetzt=System.currentTimeMillis(), lief=jetzt-start, still=jetzt-letzteAktivitaet;
     if(lief>FENSTER_MAX_MS){
      setStatus("Weckfenster: Höchstdauer erreicht");
      if(weckFensterEnde!=null)weckFensterEnde.run(); return;
     }
     if(lief>FENSTER_MIN_MS&&still>RUHE_MS){
      setStatus("Weckfenster: "+(wartung?"Raubzug":"Aktion")+" fertig nach "+(lief/1000)+" s");
      if(weckFensterEnde!=null)weckFensterEnde.run(); return;
     }
     w.getDecorView().postDelayed(this,10_000L);
    }
   };
   w.getDecorView().postDelayed(ruhePruefer,10_000L);
   weckFensterEnde=()->{
    if(!weckerAktiv)return;
    weckerAktiv=false;
    if(ruhePruefer!=null)getWindow().getDecorView().removeCallbacks(ruhePruefer);
    anzeigeZuruecksetzen();
    // Nachts nicht in den Hintergrund: dort wird nicht gerendert und
    // Chromium drosselt. Stattdessen zurueck unter die dunkle Abdeckung,
    // die im vollen Takt weiterlaeuft.
    if(dimmGewuenscht()){
     dimmenAn();
     setStatus("Weckfenster beendet – zurück in den Dimm-Modus");
     return;
    }
    if(warGeschwebt&&OdinFloat.show(this,gameAccountId,webView,this::restoreFromFloat)){
     // Zurueck ins schwebende Fenster statt in den Hintergrund: dort bleibt
     // die WebView sichtbar und damit ungedrosselt.
     setStatus("Weckfenster beendet – schwebt wieder");
    }else{
     setStatus("Weckfenster beendet – zurück in den Hintergrund");
    }
    moveTaskToBack(true);
   };
   weckerAktiv=true;
   w.getDecorView().postDelayed(weckFensterEnde,FENSTER_MAX_MS+30_000L);
  }catch(Exception e){ android.util.Log.w("ODIN_ALARM","weckerModus",e); }
 }
 private boolean dunkelWegenWecker=false, weckerAktiv=false, warGeschwebt=false;
 private Runnable weckFensterEnde=null, ruhePruefer=null;
 volatile long letzteAktivitaet=0L;
 private boolean vollbildUnterdruecken=false;
 private void systemleistenZeigen(){
  try{
   android.view.Window w=getWindow();
   w.clearFlags(android.view.WindowManager.LayoutParams.FLAG_FULLSCREEN);
   if(Build.VERSION.SDK_INT>=30){
    android.view.WindowInsetsController c=w.getInsetsController();
    if(c!=null)c.show(android.view.WindowInsets.Type.statusBars()
                     |android.view.WindowInsets.Type.navigationBars());
   }else{
    w.getDecorView().setSystemUiVisibility(android.view.View.SYSTEM_UI_FLAG_VISIBLE);
   }
  }catch(Exception ignored){}
 }
 // Das Fenster endet nicht nach fester Zeit, sondern wenn nichts mehr
 // passiert. Ein Rausstellen ist nach Sekunden erledigt, ein Raubzug ueber
 // zwanzig Doerfer braucht Minuten - eine feste Dauer passt fuer keines von
 // beiden. MIN verhindert ein Schliessen waehrend des Ladens, MAX ist die
 // Reissleine, falls der Puls nie verstummt.
 private static final long FENSTER_MIN_MS=45_000L, FENSTER_MAX_MS=12*60_000L, RUHE_MS=40_000L;
 private void anzeigeZuruecksetzen(){
  try{
   android.view.Window w=getWindow();
   android.view.WindowManager.LayoutParams lp=w.getAttributes();
   lp.screenBrightness=android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
   w.setAttributes(lp);
   w.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
   if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(false); setTurnScreenOn(false); }
  }catch(Exception ignored){}
  dunkelWegenWecker=false;
  // Nach dem Weckfenster wieder normal: im Alltag ist Vollbild gewuenscht.
  vollbildUnterdruecken=false;
 }
 // Sobald du das Geraet anfasst, wieder normale Helligkeit.
 // Nur echte Beruehrungen zaehlen. onUserInteraction() feuert auch, wenn ein
 // neuer Intent die Ansicht unterbricht - bis 1.68 brach das JEDES
 // Weckfenster in derselben Sekunde ab (23.09. 19:22 bis 21:05, achtmal).
 // Dazu 2 s Karenz nach dem Wecken.
 private long weckBeginn=0L;
 @Override public boolean dispatchTouchEvent(android.view.MotionEvent ev){
  try{
   if(ev.getActionMasked()==android.view.MotionEvent.ACTION_DOWN
      &&(dunkelWegenWecker||weckerAktiv)
      &&System.currentTimeMillis()-weckBeginn>2000L)beruehrtImWecker();
  }catch(Exception ignored){}
  return super.dispatchTouchEvent(ev);
 }
 private void beruehrtImWecker(){
  // Du hast uebernommen - dann nicht automatisch wieder wegschalten.
  weckerAktiv=false;
  if(weckFensterEnde!=null)getWindow().getDecorView().removeCallbacks(weckFensterEnde);
  anzeigeZuruecksetzen();
  setStatus("Anzeige normal – Weckfenster abgebrochen");
 }
 // Einstellungsabgleich ueber Supabase REST. Laeuft nativ, damit weder CORS
 // noch die CSP der Spielseite dazwischenfunken.
 private String supaRequest(String method,String path,String body) throws Exception {
  try{ return supaEinmal(method,path,body); }
  catch(java.io.IOException e){
   String m=e.getMessage()==null?"":e.getMessage();
   if(!(m.startsWith("HTTP 401")||m.startsWith("HTTP 403")))throw e;
   if(!OdinService.erneuern(this,"supaRequest "+method+" "+path))throw e;
   supaToken=OdinService.token;
   return supaEinmal(method,path,body);
  }
 }
 private String supaEinmal(String method,String path,String body) throws Exception {
  java.net.HttpURLConnection c=(java.net.HttpURLConnection)new java.net.URL(supaUrl+"/rest/v1/"+path).openConnection();
  c.setRequestMethod(method); c.setConnectTimeout(15000); c.setReadTimeout(30000);
  c.setRequestProperty("apikey",supaKey);
  c.setRequestProperty("Authorization","Bearer "+supaToken);
  c.setRequestProperty("Content-Type","application/json");
  c.setRequestProperty("Accept","application/json");
  if(body!=null){
   c.setRequestProperty("Prefer","resolution=merge-duplicates,return=minimal");
   c.setDoOutput(true);
   java.io.OutputStream os=c.getOutputStream(); os.write(body.getBytes("UTF-8")); os.close();
  }
  int st=c.getResponseCode();
  java.io.InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();
  StringBuilder b=new StringBuilder();
  if(in!=null){ BufferedReader r=new BufferedReader(new InputStreamReader(in,"UTF-8"));
   String l; while((l=r.readLine())!=null)b.append(l); r.close(); }
  if(st<200||st>=400) throw new java.io.IOException("HTTP "+st+" "+b);
  OdinService.erfolg();
  return b.toString();
 }
 // Automatische Anmeldung NUR auf dem Geraet, dem das Konto zugewiesen ist.
 // Sonst werfen sich zwei Geraete mit hinterlegten Zugangsdaten gegenseitig
 // aus dem Spiel (eine Sitzung je Welt) und melden sich immer wieder an -
 // ein auffaelliges Muster auf dem Spielserver. Die Pruefung braucht das
 // Netz, deshalb im Hintergrund; ein freies Konto wird dabei diesem Geraet
 // zugewiesen.
 private void anmeldenWennNoetig(WebView v){
  if(gameAccountId.isEmpty())return;
  if(!OdinVault.vorhanden(this,gameAccountId))return;
  final String k=gameAccountId;
  new Thread(()->{
   boolean darf=OdinService.darfLaufen(getApplicationContext(),k);
   runOnUiThread(()->{
    if(darf)anmeldenJetzt(v);
    else{
     String h=OdinService.fremdHalter(k);
     setStatus("Keine automatische Anmeldung - Konto ist "+(h==null?"einem anderen Gerät":h)+" zugewiesen");
     OdinService.WARTET.add(k);
     if(leaseKnopf!=null)leaseKnopf.setVisibility(android.view.View.VISIBLE);
    }
   });
  }).start();
 }
 private void anmeldenJetzt(WebView v){
  try{
   if(gameAccountId.isEmpty())return;
   String[] d=OdinVault.lesen(this,gameAccountId); if(d==null)return;
   String u=org.json.JSONObject.quote(d[0]), p=org.json.JSONObject.quote(d[1]);
   String js="(function(u,p){try{\n var f=document.getElementById('login_form'); if(!f) return 'kein_formular';\n var un=document.getElementById('user'), pw=document.getElementById('password');\n if(!un||!pw) return 'felder_fehlen';\n if(un.value && pw.value) return 'schon_gefuellt';\n function setz(el,v){\n  var d=Object.getOwnPropertyDescriptor(el.constructor.prototype,'value');\n  if(d&&d.set)d.set.call(el,v); else el.value=v;\n  el.dispatchEvent(new Event('input',{bubbles:true}));\n  el.dispatchEvent(new Event('change',{bubbles:true}));\n }\n setz(un,u); setz(pw,p);\n var rm=document.getElementById('remember-me'); if(rm&&!rm.checked)rm.click();\n // Das Formular hat action=\"#\" - abgeschickt wird ueber den Link, nicht submit.\n var btn=document.querySelector('a.btn-login');\n if(btn){ btn.click(); return 'abgeschickt'; }\n var sb=document.getElementById('login_submit_button');\n if(sb){ sb.click(); return 'abgeschickt_knopf'; }\n return 'kein_knopf';\n}catch(e){return 'fehler: '+e.message}})"+"("+u+","+p+");";
   v.evaluateJavascript(js,r->{
    String t=r==null?"":r.replace("\"","");
    if(!"kein_formular".equals(t))setStatus("Anmeldung: "+t);
   });
  }catch(Exception e){ setStatus("Anmeldung fehlgeschlagen: "+e.getMessage()); }
 }
 private void injectManagedScripts(WebView v){try{BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("game-scripts.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\n');r.close();v.evaluateJavascript(b.toString(),null);}catch(Exception e){Log.e("ODIN","bootstrap",e);}}
 private void loadEnabledScripts(WebView v){ }
 private void executeGodBotWhenReady(WebView v){ }
 private void injectGodBot(WebView v){ }
 private WebResourceResponse odinIntercept(WebResourceRequest r){ return null; }
 @Override public void onWindowFocusChanged(boolean f){
  super.onWindowFocusChanged(f);
  if(f){ if(vollbildUnterdruecken)systemleistenZeigen(); else Fullscreen.apply(this); }
 }
 // Einzige Stelle, an der die Sitzung aus der dauerhaften Ablage kommt.
 // Leere Werte ueberschreiben nie vorhandene - der Dienst haelt den Token
 // aktuell, die Ansicht soll ihn uebernehmen, nicht wegwerfen.
 private void sitzungNachladen(){
  OdinService.ladeStatisch(this);
  if(!OdinService.url.isEmpty())supaUrl=OdinService.url;
  if(!OdinService.key.isEmpty())supaKey=OdinService.key;
  if(!OdinService.token.isEmpty())supaToken=OdinService.token;
  if(!OdinService.team.isEmpty())supaTeam=OdinService.team;
 }
 @Override protected void onNewIntent(Intent in){
  super.onNewIntent(in); setIntent(in);
  // Nur die Sitzungsdaten auffrischen - die WebView bleibt unberuehrt,
  // sonst ginge die Anmeldung bei jedem Wechsel verloren.
  String u=nz(in.getStringExtra("supaUrl")), k=nz(in.getStringExtra("supaKey"));
  String t=nz(in.getStringExtra("supaToken")), tm=nz(in.getStringExtra("supaTeam"));
  // Wecker und Dimm-Waechter starten die Ansicht ohne Sitzung im Intent.
  // Bisher wurden die Felder trotzdem mit leeren Werten ueberschrieben -
  // ab da lief die Ansicht bis zum Neustart ohne Abgleich. Im Protokoll
  // vom 19.09. ab 20:24 durchgehend "Abgleich inaktiv (keine Sitzung)",
  // ueber sechs Stunden, waehrend der Dienst munter weiter erneuerte.
  if(!u.isEmpty()&&!t.isEmpty()){ supaUrl=u; supaKey=k; supaToken=t; supaTeam=tm; }
  else sitzungNachladen();
  String a=nz(in.getStringExtra("accountId")); if(!a.isEmpty())gameAccountId=a;
  // Frueher lief der Weckermodus nur in onCreate. Existierte die Ansicht
  // bereits, kam onNewIntent dran und der Bildschirm blieb aus.
  weckerModus();
 }
 @Override protected void onResume(){
  super.onResume();
  imVordergrund=true;
  // Der Dienst erneuert den Token stuendlich. Ohne diese Zeile arbeitet die
  // Ansicht mit dem Exemplar von ihrem Start weiter.
  sitzungNachladen();
  if(vollbildUnterdruecken)systemleistenZeigen(); else Fullscreen.apply(this);
  OdinBubble.hide(); restoreFromFloat();
 }
 @Override protected void onPause(){
  super.onPause();
  if(imVordergrund)OdinService.vorn(gameAccountId);
  imVordergrund=false;
  if(dimDecke!=null){
   try{
    android.os.PowerManager pm=(android.os.PowerManager)getSystemService(POWER_SERVICE);
    android.app.KeyguardManager km=getSystemService(android.app.KeyguardManager.class);
    setStatus("Dimm-Modus verlässt den Vordergrund - Bildschirm="
      +(pm!=null&&pm.isInteractive()?"an":"aus")+", gesperrt="+(km!=null&&km.isKeyguardLocked()));
   }catch(Exception ignored){}
  }
  // Ohne flush() bleiben die Anmeldecookies nur im Speicher und sind nach
  // einem Neuaufbau des Prozesses weg.
  try{ android.webkit.CookieManager.getInstance().flush(); }catch(Exception ignored){}
  warteschlangeLeeren();   // offene Protokolleintraege nicht verlieren
  try{ if(webView!=null&&webView.getUrl()!=null)
        getSharedPreferences("odin",MODE_PRIVATE).edit()
          .putString("lastGameUrl",webView.getUrl()).apply(); }catch(Exception ignored){}
 }
 // Holt die WebView aus dem schwebenden Fenster zurueck in die Activity.
 // Wichtig: dieselbe Instanz, damit die Spielsitzung nicht neu laedt.
 // Nur zurueckhaengen, ohne die App nach vorne zu holen. Wird gebraucht, wenn
 // das kleine Fenster nach getaner Arbeit von selbst schliessen soll.
 private void holeAusFenster(boolean nachVorne){
  if(!OdinFloat.active(gameAccountId))return;
  WebView w=OdinFloat.hide(gameAccountId);
  if(w==null||rootLayout==null)return;
  webView=w;
  runOnUiThread(()->{
   try{
    if(w.getParent() instanceof android.view.ViewGroup)
     ((android.view.ViewGroup)w.getParent()).removeView(w);
    w.setScaleX(1f); w.setScaleY(1f);
    w.setLayoutParams(new LinearLayout.LayoutParams(-1,0,1f));
    rootLayout.addView(w,1,new LinearLayout.LayoutParams(-1,0,1f));
    w.requestLayout(); w.invalidate();
    if(nachVorne){
     Intent i=new Intent(this,GameWebViewActivity.class);
     if(!gameAccountId.isEmpty()){
      i.setData(android.net.Uri.parse("odin://account/"+gameAccountId));
      i.putExtra("accountId",gameAccountId);
     }
     i.putExtra("supaUrl",supaUrl); i.putExtra("supaKey",supaKey);
     i.putExtra("supaToken",supaToken); i.putExtra("supaTeam",supaTeam);
     i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT|Intent.FLAG_ACTIVITY_SINGLE_TOP);
     startActivity(i);
     setStatus("zurueck im Vordergrund");
    }else{
     setStatus("Fenster geschlossen - bis zum nächsten Termin pausiert");
    }
   }catch(Exception e){android.util.Log.e("ODIN_FLOAT","restore",e);}
  });
 }
 private void restoreFromFloat(){ holeAusFenster(true); }
 @Override protected void onDestroy(){
  if(OFFEN.get(gameAccountId)==this){
   OFFEN.remove(gameAccountId);
   // Geraete-Sperre sofort freigeben, damit ein anderes Geraet nicht die
   // 3 Minuten Frist abwarten muss.
   final String k=gameAccountId; final Context app=getApplicationContext();
   OdinService.WARTET.remove(k);
   new Thread(()->OdinService.leaseFreigeben(app,k)).start();
  }
  super.onDestroy();
 }
 static java.util.Set<String> offeneKonten(){
  synchronized(OFFEN){ return new java.util.HashSet<>(OFFEN.keySet()); }
 }
 static void neuLadenFuer(String konto,String grund){
  final GameWebViewActivity a;
  synchronized(OFFEN){ a=OFFEN.get(konto); }
  if(a==null||a.isFinishing())return;
  a.runOnUiThread(()->{
   a.setStatus(grund);
   if(a.leaseKnopf!=null)a.leaseKnopf.setVisibility(android.view.View.GONE);
   try{ a.webView.setTag(0x0D1A0001,null); a.webView.reload(); }catch(Exception ignored){}
  });
 }
 // Sichtbar nur, solange ein anderes Geraet das Konto fuehrt.
 Button leaseKnopf;
 void leaseGesperrtAnzeigen(String halter){
  runOnUiThread(()->{
   if(leaseKnopf!=null)leaseKnopf.setVisibility(android.view.View.VISIBLE);
   setStatus("GodBot pausiert - läuft auf "+halter+". „Übernehmen“ holt ihn hierher.");
  });
 }
 @Override public void onBackPressed(){
  if(dimDecke!=null){dimmenAus();return;}
  // Zurueck ist ein Seitenwechsel wie jeder andere: laeuft gerade ein
  // Vorgang (Stand der GodBot-Leiste, hoechstens 30 s alt), erst fragen.
  org.json.JSONObject st=godbotStand;
  String lauf=st==null?"":st.optString("laeuft","");
  boolean frisch=st!=null&&System.currentTimeMillis()-st.optLong("at",0)<30000L;
  if(frisch&&!lauf.isEmpty()&&!"null".equals(lauf)&&webView.canGoBack()){
   new android.app.AlertDialog.Builder(this)
    .setTitle("GodBot arbeitet gerade")
    .setMessage("Ein Seitenwechsel jetzt bricht den laufenden Vorgang ("+lauf+") ab.")
    .setPositiveButton("Hierbleiben",null)
    .setNegativeButton("Trotzdem zurück",(d,w)->{ if(webView.canGoBack())webView.goBack(); })
    .show();
   return;
  }
  if(webView.canGoBack())webView.goBack();else super.onBackPressed();
 }
 private void minimizeToApp(){finish();}
 private class OdinNative{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public void status(String m){setStatus(m==null?"":m);}
  // Lebenszeichen aus der Seite: GodBot schreibt bei jedem Arbeitsschritt in
  // den localStorage. Bleibt das aus, ist der Durchlauf fertig.
  @JavascriptInterface public void puls(){ letzteAktivitaet=System.currentTimeMillis(); }
  // window.Odin.lebt / window.Odin.termin (godbot/GodBot.user.js, Odin-Anbindung)
  @JavascriptInterface public void lebt(){ OdinService.lebt(gameAccountId); }
  @JavascriptInterface public void termin(String skey,String art,String ms){
   long z; try{ z=Long.parseLong(ms); }catch(Exception e){ return; }
   OdinService.appTermin(GameWebViewActivity.this,gameAccountId,kopfName,skey,art,z);
  }
  // GodBots Protokoll-Download landete im Nichts: <a download> mit einer
  // blob:-Adresse erreicht den Download-Weg von Android nicht. Der Loader
  // faengt den Klick ab und reicht den Text hierher.
  @JavascriptInterface public void saveText(String name,String text){
   final String sicher0=(name==null||name.trim().isEmpty()?"odin.txt":name.trim())
     .replaceAll("[^A-Za-z0-9._-]","_");
   final String sicher=sicher0.toLowerCase().endsWith(".txt")?sicher0:sicher0+".txt";
   final String inhalt=(text==null?"":text);
   // Denselben Weg wie beim APK-Download nehmen: Datei in den Zwischenspeicher,
   // dann ueber den FileProvider weiterreichen. Der Benutzer waehlt selbst, wo
   // sie landet - Dateien, Mail, Chat.
   new Thread(()->{
    try{
     java.io.File out=new java.io.File(getCacheDir(),sicher);
     java.io.FileOutputStream fo=new java.io.FileOutputStream(out);
     byte[] roh=inhalt.getBytes("UTF-8");
     fo.write(roh); fo.close();
     android.net.Uri uri=androidx.core.content.FileProvider.getUriForFile(
       GameWebViewActivity.this,"de.teamzentrale.odin.fileprovider",out);
     Intent i=new Intent(Intent.ACTION_SEND);
     i.setType("text/plain");
     i.putExtra(Intent.EXTRA_STREAM,uri);
     i.putExtra(Intent.EXTRA_SUBJECT,sicher);
     i.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
     Intent w=Intent.createChooser(i,sicher);
     w.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
     setStatus("Datei bereit: "+sicher+" ("+roh.length+" B)");
     OdinLog.schreib(GameWebViewActivity.this,gameAccountId,"info",
       "Datei bereitgestellt: "+sicher+" ("+roh.length+" B)");
     runOnUiThread(()->{ try{ startActivity(w); }catch(Exception e){
       setStatus("Teilen fehlgeschlagen: "+e.getMessage()); } });
    }catch(Exception e){ setStatus("Download fehlgeschlagen: "+e.getMessage()); }
   }).start();
  }
  @JavascriptInterface public boolean syncReady(){ return !supaUrl.isEmpty()&&!supaToken.isEmpty()&&!gameAccountId.isEmpty(); }
  @JavascriptInterface public String settingsLoad(){
   try{
    if(!syncReady())return "{}";
    // Mit updated_at: der Bootstrap entscheidet damit, ob der Serverstand
    // juenger ist als die letzte oertliche Aenderung.
    String q="godbot_settings?select=skey,value,updated_at&account_id=eq."+java.net.URLEncoder.encode(gameAccountId,"UTF-8");
    String json=supaRequest("GET",q,null);
    org.json.JSONArray arr=new org.json.JSONArray(json);
    org.json.JSONObject out=new org.json.JSONObject();
    for(int i=0;i<arr.length();i++){
     org.json.JSONObject o=arr.getJSONObject(i);
     org.json.JSONObject e=new org.json.JSONObject();
     e.put("v",o.getString("value")); e.put("u",o.optString("updated_at",""));
     out.put(o.getString("skey"),e);
    }
    setStatus("Einstellungen geladen ("+out.length()+")");
    return out.toString();
   }catch(Exception e){ setStatus("Abgleich lesen fehlgeschlagen: "+e.getMessage()); return "{}"; }
  }
  // GodBot kann Meldungen an alle Geraete des Teams schicken - ohne Discord.
  @JavascriptInterface public boolean notify(String title,String body,String level){
   // Erst oertlich zustellen: Benachrichtigung, Angriffsbuendelung und der
   // Botschutz-Wecker haengen damit nicht mehr am Netz. Danach wie bisher
   // in die Tabelle, damit die anderen Geraete des Teams sie bekommen.
   OdinService.meldungAusSpiel(title,body,level);
   try{
    if(!syncReady())return false;
    // Ohne das kann source leer sein - dann erkennt poll() die eigene Zeile
    // nicht wieder und zeigt sie als fremde Meldung an.
    OdinService.ladeStatisch(GameWebViewActivity.this);
    org.json.JSONObject row=new org.json.JSONObject();
    row.put("team_id",supaTeam); row.put("account_id",gameAccountId);
    row.put("title",title==null?"Odin":title); row.put("body",body==null?"":body);
    row.put("level",level==null?"info":level); row.put("source",OdinService.device);
    supaRequest("POST","notifications",new org.json.JSONArray().put(row).toString());
    setStatus("Meldung gesendet: "+title);
    return true;
   }catch(Exception e){ setStatus("Meldung fehlgeschlagen: "+e.getMessage()); return false; }
  }
  @JavascriptInterface public boolean settingsSave(String pairsJson){
   try{
    if(!syncReady())return false;
    org.json.JSONObject in=new org.json.JSONObject(pairsJson);
    org.json.JSONArray rows=new org.json.JSONArray();
    java.util.Iterator<String> it=in.keys();
    while(it.hasNext()){ String k=it.next();
     org.json.JSONObject r=new org.json.JSONObject();
     r.put("team_id",supaTeam); r.put("account_id",gameAccountId);
     r.put("skey",k); r.put("value",in.getString(k)); rows.put(r); }
    if(rows.length()==0)return true;
    supaRequest("POST","godbot_settings?on_conflict=account_id,skey",rows.toString());
    // Meldung kommt aus dem Bootstrap inklusive Schluesselnamen.
    return true;
   }catch(Exception e){ setStatus("Abgleich schreiben fehlgeschlagen: "+e.getMessage()); return false; }
  }
  // Steuerzentrale (1.79.0): Befehle der App an GodBot. Nur offene Zeilen
  // dieses Kontos, aelteste zuerst. Erledigt wird ueber eine RPC, weil
  // HttpURLConnection kein PATCH kann.
  // Nicht blockierend: GodBot arbeitet teils sekundengenau (Rausstellen).
  // Eine Netzabfrage auf dem JS-Faden alle 10 s waere dort spuerbar. Das
  // Ergebnis kommt deshalb per evaluateJavascript zurueck.
  // GodBot meldet seinen Stand fuer die GodBot-Leiste (Odin.stand).
  @JavascriptInterface public void steuerstand(String json){ if(json!=null)godbotStandEmpfangen(json); }
  @JavascriptInterface public void befehleAbrufen(){
   if(!syncReady())return;
   new Thread(()->{
    try{
     String q="godbot_befehle?select=id,pfad,wert,erstellt_at&erledigt_at=is.null&order=id.asc&limit=20&account_id=eq."
       +java.net.URLEncoder.encode(gameAccountId,"UTF-8");
     String json=supaRequest("GET",q,null);
     if(json==null)return; json=json.trim();
     if(!json.startsWith("[")||json.equals("[]"))return;
     final String js="(function(){try{if(window.__odinBefehle)window.__odinBefehle("+json+")}catch(e){}})()";
     runOnUiThread(()->{ try{ if(webView!=null)webView.evaluateJavascript(js,null); }catch(Exception ignored){} });
    }catch(Exception ignored){}
   }).start();
  }
  @JavascriptInterface public void befehlErledigt(String id,boolean ok,String ergebnis){
   if(!syncReady())return;
   new Thread(()->{
    try{
     org.json.JSONObject b=new org.json.JSONObject();
     b.put("p_id",Long.parseLong(id)); b.put("p_ok",ok); b.put("p_ergebnis",ergebnis==null?"":ergebnis);
     supaRequest("POST","rpc/godbot_befehl_erledigt",b.toString());
     OdinLog.schreib(GameWebViewActivity.this,gameAccountId,ok?"info":"warn",
       "App-Befehl "+(ok?"übernommen":"nicht übernommen")+": "+(ergebnis==null?"":ergebnis));
    }catch(Exception e){ setStatus("Befehl bestätigen fehlgeschlagen: "+e.getMessage()); }
   }).start();
  }
  @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setInstanceFollowRedirects(true);c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)throw new IOException("HTTP "+st);BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}
 private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}
}
EOF
printf '%s\n' "ODIN $VERSION · clean generator"
