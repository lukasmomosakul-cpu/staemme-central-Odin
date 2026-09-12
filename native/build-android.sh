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
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
    <uses-sdk android:minSdkVersion="26" />
    <application android:theme="@style/AppTheme" android:label="Odin" android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher" android:roundIcon="@mipmap/ic_launcher_round">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop"
            android:configChanges="orientation|screenSize|keyboardHidden|screenLayout|uiMode"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".GameWebViewActivity" android:exported="false"
            android:documentLaunchMode="intoExisting" android:launchMode="singleTop"
            android:configChanges="orientation|screenSize|keyboardHidden|screenLayout|uiMode" />
        <receiver android:name=".OdinAlarmReceiver" android:exported="false" />
        <receiver android:name=".OdinBootReceiver" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>
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
  @JavascriptInterface public void openGameOnWorld(String accountId,String username,String accountsJson,String world){
   gameWorld=world==null?"":world.trim().toLowerCase();
   runOnUiThread(()->openGameActivity(accountId==null?"":accountId,username==null?"":username,accountsJson));
  }
  // Die Spielansicht hat keine eigene Supabase-Sitzung. Der Webcode reicht
  // Zugangstoken und Team hier durch, damit die Einstellungen abgeglichen
  // werden koennen.
  @JavascriptInterface public void setSupabaseSession(String url,String anonKey,String accessToken,String teamId){
   SUPA_URL=url; SUPA_KEY=anonKey; SUPA_TOKEN=accessToken; SUPA_TEAM=teamId;
   OdinService.url=url; OdinService.key=anonKey; OdinService.token=accessToken;
   OdinService.sichern(MainActivity.this,url,anonKey,accessToken,teamId);
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
 static String url="",key="",token="",team="",device="",account="";
 private PowerManager.WakeLock lock;
 private Thread poller; private volatile boolean running;
 private String lastSeen="";
 @Override public IBinder onBind(Intent i){ return null; }
 // Ohne dauerhafte Ablage stehen die Zugangsdaten nur in statischen Feldern:
 // nach einem Neustart oder wenn Android die App abraeumt, waeren sie weg und
 // es wuerden keine Wecker mehr gesetzt.
 public static void sichern(Context c,String u,String k,String t,String tm){
  c.getSharedPreferences("odin_svc",Context.MODE_PRIVATE).edit()
   .putString("url",u).putString("key",k).putString("token",t).putString("team",tm).apply();
 }
 private void laden(){
  android.content.SharedPreferences p=getSharedPreferences("odin_svc",Context.MODE_PRIVATE);
  if(url.isEmpty())url=p.getString("url","");
  if(key.isEmpty())key=p.getString("key","");
  if(token.isEmpty())token=p.getString("token","");
  if(team.isEmpty())team=p.getString("team","");
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
  running=true; poller=new Thread(this::loop); poller.start();
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
 private void loop(){
  int runde=0;
  while(running){
   try{ poll(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","poll",e); }
   // Wecker alle 10 Runden (5 Minuten) neu setzen: Plaene aendern sich, und
   // Android begrenzt die Zahl gleichzeitiger exakter Alarme.
   if(runde%10==0){ try{ weckerNeuSetzen(); }catch(Exception e){ android.util.Log.w("ODIN_SVC","alarm",e); } }
   runde++;
   try{ Thread.sleep(30000); }catch(InterruptedException e){ return; }
  }
 }
 private String hole(String pfad) throws Exception {
  HttpURLConnection c=(HttpURLConnection)new URL(url+"/rest/v1/"+pfad).openConnection();
  c.setRequestProperty("apikey",key); c.setRequestProperty("Authorization","Bearer "+token);
  c.setConnectTimeout(15000); c.setReadTimeout(20000);
  if(c.getResponseCode()>=400)return "[]";
  BufferedReader r=new BufferedReader(new InputStreamReader(c.getInputStream(),"UTF-8"));
  StringBuilder b=new StringBuilder(); String l; while((l=r.readLine())!=null)b.append(l); r.close();
  return b.toString();
 }
 // Wecker fuer ALLE Accounts des Teams. Echte Parallelitaet gibt es nicht -
 // nur die sichtbare WebView laeuft ungedrosselt. Stattdessen wird jeweils
 // der Account nach vorne geholt, der als naechstes einen Termin hat.
 private void weckerNeuSetzen() throws Exception {
  if(url.isEmpty()||token.isEmpty()||team.isEmpty())return;
  JSONArray accs=new JSONArray(hole("game_accounts?select=id,name,world&team_id=eq."
    +java.net.URLEncoder.encode(team,"UTF-8")));
  OdinAlarm.zuruecksetzen(this);
  int gesamt=0;
  for(int i=0;i<accs.length();i++){
   JSONObject a=accs.getJSONObject(i);
   String id=a.optString("id",""); if(id.isEmpty())continue;
   String bez=a.optString("name","")+" · "+a.optString("world","");
   JSONArray s=new JSONArray(hole("godbot_settings?select=value&skey=eq.tw_tabben_plan&account_id=eq."
     +java.net.URLEncoder.encode(id,"UTF-8")));
   if(s.length()==0)continue;
   gesamt+=OdinAlarm.planen(this,s.getJSONObject(0).optString("value","{}"),id,bez);
  }
  android.util.Log.i("ODIN_ALARM","Wecker gesetzt: "+gesamt+" ueber "+accs.length()+" Accounts");
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
  if(c.getResponseCode()>=400)return;
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
 private void show(String title,String body,String level){
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
  running=false; if(poller!=null)poller.interrupt();
  try{ if(lock!=null&&lock.isHeld())lock.release(); }catch(Exception ignored){}
  super.onDestroy();
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
 public static void loeschen(Context c,String accountId){
  p(c).edit().remove(accountId).remove(accountId+"_ivlen").apply();
 }
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
   EXTRA_ACCOUNT="odin_account";
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
  String info=in.getStringExtra(OdinAlarm.EXTRA_INFO); if(info==null)info="";
  String acc=in.getStringExtra(OdinAlarm.EXTRA_ACCOUNT); if(acc==null)acc="";
  Intent open=new Intent(c,GameWebViewActivity.class);
  open.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK|Intent.FLAG_ACTIVITY_REORDER_TO_FRONT);
  // Dieselbe Daten-URI wie beim Oeffnen aus Odin: dadurch kommt genau die
  // Ansicht dieses Accounts nach vorne statt irgendeiner.
  if(!acc.isEmpty()){ open.setData(android.net.Uri.parse("odin://account/"+acc));
                      open.putExtra("accountId",acc); }
  open.putExtra("fromAlarm",true);
  PendingIntent pi=PendingIntent.getActivity(c,4242,open,
    PendingIntent.FLAG_UPDATE_CURRENT|PendingIntent.FLAG_IMMUTABLE);
  Notification n=new Notification.Builder(c,OdinService.CH_WAKE)
    .setContentTitle("Rausstellen fällig").setContentText(info)
    .setSmallIcon(android.R.drawable.ic_dialog_info)
    .setCategory(Notification.CATEGORY_ALARM)
    .setFullScreenIntent(pi,true)     // oeffnet direkt, auch gesperrt
    .setAutoCancel(true).build();
  c.getSystemService(NotificationManager.class).notify((int)(System.currentTimeMillis()%90000),n);
  try{ c.startActivity(open); }catch(Exception e){ android.util.Log.w("ODIN_ALARM","start",e); }
 }
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
 private static final int LAY_W=420, LAY_H=740, WIN=150;
 private static class Fenster {
  View rahmen; WebView web; WindowManager wm;
 }
 private static final Map<String,Fenster> offen=new LinkedHashMap<>();

 public static boolean allowed(Context c){ return Settings.canDrawOverlays(c); }
 public static synchronized boolean active(String accountId){ return offen.containsKey(schluessel(accountId)); }
 public static synchronized int anzahl(){ return offen.size(); }
 private static String schluessel(String a){ return a==null||a.isEmpty()?"_":a; }

 public static synchronized boolean show(Context ctx,String accountId,WebView web,Runnable onRestore){
  final Context app=ctx.getApplicationContext();
  final String key=schluessel(accountId);
  if(offen.containsKey(key)||web==null||!allowed(app))return false;
  try{
   if(web.getParent() instanceof ViewGroup)((ViewGroup)web.getParent()).removeView(web);

   FrameLayout box=new FrameLayout(app);
   FrameLayout.LayoutParams wlp=new FrameLayout.LayoutParams(LAY_W,LAY_H);
   web.setLayoutParams(wlp); web.setPivotX(0f); web.setPivotY(0f);
   float scale=Math.min((float)WIN/LAY_W,(float)WIN/LAY_H);
   web.setScaleX(scale); web.setScaleY(scale);
   box.addView(web);

   TextView symbol=new TextView(app); symbol.setText("⚔");
   symbol.setTextColor(0xFFFFFFFF); symbol.setTextSize(24f);
   symbol.setGravity(Gravity.CENTER);
   android.graphics.drawable.GradientDrawable g=new android.graphics.drawable.GradientDrawable();
   g.setShape(android.graphics.drawable.GradientDrawable.OVAL);
   g.setColor(0xFF2B2B2B); g.setStroke(3,0xFFFFFFFF); symbol.setBackground(g);
   box.addView(symbol,new FrameLayout.LayoutParams(-1,-1));

   int type=Build.VERSION.SDK_INT>=26?WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                                     :WindowManager.LayoutParams.TYPE_PHONE;
   final WindowManager.LayoutParams lp=new WindowManager.LayoutParams(WIN,WIN,type,
     WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE, PixelFormat.OPAQUE);
   lp.gravity=Gravity.TOP|Gravity.START; lp.x=16;
   // Versetzt stapeln, damit sich mehrere Symbole nicht ueberdecken.
   lp.y=180+offen.size()*(WIN+24);

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
 public static void setReturnTarget(Class<?> c){ if(c!=null)returnTo=c; }
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
import android.annotation.SuppressLint; import android.app.Activity; import android.content.Intent; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.widget.LinearLayout; import android.widget.TextView; import android.widget.Button; import android.widget.HorizontalScrollView; import android.util.Log; import android.os.Build; import android.webkit.JavascriptInterface; import java.io.*; import java.net.*; import org.json.JSONObject;
public class GameWebViewActivity extends Activity {
 private WebView webView;
 private TextView statusView;
 // Zwischenspeicher fuer die vom Bootstrap angeforderten Skripte.
 private volatile String godbotSrc;
 private volatile java.util.List<String> godbotDeps=new java.util.ArrayList<>();
 private String supaUrl="",supaKey="",supaToken="",supaTeam="",gameAccountId="";
 private LinearLayout rootLayout;
 private FrameLayout dimRahmen;
 private android.view.View dimDecke;
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
  OdinLog.schreib(this,kopfName,stufe,msg);
  // Nur Auffaelliges wandert nach Odin: sonst wuerde jede Routinemeldung eine
  // eigene Anfrage ausloesen, und im Protokoll ginge das Wesentliche unter.
  if(!"info".equals(stufe))ereignisMelden(stufe,bereichVon(msg),msg);
 }
 private static String bereichVon(String m){
  if(m.contains("Anmeldung"))return "anmeldung";
  if(m.contains("Wecker"))return "wecker";
  if(m.contains("Abgleich")||m.contains("Einstellungen"))return "abgleich";
  if(m.contains("Zugangssperre")||m.contains("Bruecke")||m.contains("Quelle"))return "godbot";
  return "app";
 }
 private void ereignisMelden(String stufe,String bereich,String text){
  if(supaUrl.isEmpty()||supaToken.isEmpty()||supaTeam.isEmpty())return;
  new Thread(()->{
   try{
    org.json.JSONObject r=new org.json.JSONObject();
    r.put("team_id",supaTeam);
    if(!gameAccountId.isEmpty())r.put("account_id",gameAccountId);
    r.put("level",stufe); r.put("bereich",bereich); r.put("message",text);
    r.put("device",android.os.Build.MODEL); r.put("app_version",apkVersion());
    supaRequest("POST","app_events",new org.json.JSONArray().put(r).toString());
   }catch(Exception e){ android.util.Log.w("ODIN_EVENT","melden",e); }
  }).start();
 }
 private String kopfName="";
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
  supaUrl=nz(getIntent().getStringExtra("supaUrl")); supaKey=nz(getIntent().getStringExtra("supaKey"));
  supaToken=nz(getIntent().getStringExtra("supaToken")); supaTeam=nz(getIntent().getStringExtra("supaTeam"));
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
 @Override public boolean onShowFileChooser(WebView v,ValueCallback<android.net.Uri[]> cb,FileChooserParams p){cb.onReceiveValue(null);return true;}
 @Override public void onPermissionRequest(final PermissionRequest r){runOnUiThread(()->r.deny());}});webView.addJavascriptInterface(new OdinNative(),"OdinNative");webView.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return false;}
 @Override public WebResourceResponse shouldInterceptRequest(WebView v,WebResourceRequest r){WebResourceResponse x=odinIntercept(r);return x!=null?x:super.shouldInterceptRequest(v,r);}
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
  Button dim=new Button(this); dim.setText("🌙"); dim.setTextSize(12f); dim.setAllCaps(false);
  dim.setPadding(10,0,10,0);
  dim.setOnClickListener(x->dimmenAn());
  bar.addView(dim,new LinearLayout.LayoutParams(-2,-2));
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
    OdinBubble.setReturnTarget(GameWebViewActivity.class);
    OdinBubble.show(this);
    setStatus("minimiert (gedrosselt)");
    moveTaskToBack(true);
   }
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
    String name="acc_"+accountId.replaceAll("[^A-Za-z0-9]","");
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
 private void dimmenAn(){
  if(dimDecke!=null||dimRahmen==null)return;
  android.widget.LinearLayout decke=new android.widget.LinearLayout(this);
  decke.setOrientation(android.widget.LinearLayout.VERTICAL);
  decke.setGravity(android.view.Gravity.CENTER);
  decke.setBackgroundColor(0xFF000000);
  TextView hin=new TextView(this);
  hin.setText("⚔  Odin läuft\n\nTippen zum Aufwecken");
  hin.setTextColor(0xFF202020); hin.setTextSize(13f);
  hin.setGravity(android.view.Gravity.CENTER);
  decke.addView(hin);
  decke.setOnClickListener(v->dimmenAus());
  dimRahmen.addView(decke,new FrameLayout.LayoutParams(-1,-1));
  dimDecke=decke;
  android.view.Window w=getWindow();
  android.view.WindowManager.LayoutParams lp=w.getAttributes();
  lp.screenBrightness=0f; w.setAttributes(lp);
  w.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  setStatus("gedimmt - läuft im vollen Takt weiter");
 }
 private void dimmenAus(){
  if(dimDecke==null)return;
  try{ dimRahmen.removeView(dimDecke); }catch(Exception ignored){}
  dimDecke=null;
  android.view.Window w=getWindow();
  android.view.WindowManager.LayoutParams lp=w.getAttributes();
  lp.screenBrightness=android.view.WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE;
  w.setAttributes(lp);
  w.clearFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
  setStatus("Anzeige normal");
 }
 private void weckerModus(){
  try{
   if(!getIntent().getBooleanExtra("fromAlarm",false))return;
   android.view.Window w=getWindow();
   if(Build.VERSION.SDK_INT>=27){ setShowWhenLocked(true); setTurnScreenOn(true); }
   else w.addFlags(android.view.WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED
                  |android.view.WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON);
   w.addFlags(android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
   // Der Bildschirm MUSS an sein, sonst rendert Chromium die WebView nicht
   // und die Zeitgeber bleiben gedrosselt. Er darf aber dunkel sein:
   // Helligkeit 0 ist die niedrigste Stufe, nicht "aus".
   android.view.WindowManager.LayoutParams lp=w.getAttributes();
   lp.screenBrightness=0f; w.setAttributes(lp);
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
   warGeschwebt=OdinFloat.active(gameAccountId);
   if(warGeschwebt){ restoreFromFloat(); setStatus("Wecker: aus dem Symbol zurückgeholt"); }
   if(weckFensterEnde!=null)w.getDecorView().removeCallbacks(weckFensterEnde);
   weckFensterEnde=()->{
    if(!weckerAktiv)return;
    weckerAktiv=false;
    anzeigeZuruecksetzen();
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
   w.getDecorView().postDelayed(weckFensterEnde,WECK_FENSTER_MS);
  }catch(Exception e){ android.util.Log.w("ODIN_ALARM","weckerModus",e); }
 }
 private boolean dunkelWegenWecker=false, weckerAktiv=false, warGeschwebt=false;
 private Runnable weckFensterEnde=null;
 // Vorlauf (90 s) plus Puffer fuer Laden und Absetzen des Befehls.
 private static final long WECK_FENSTER_MS=180_000L;
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
 }
 // Sobald du das Geraet anfasst, wieder normale Helligkeit.
 @Override public void onUserInteraction(){
  super.onUserInteraction();
  if(!dunkelWegenWecker&&!weckerAktiv)return;
  // Du hast uebernommen - dann nicht automatisch wieder wegschalten.
  weckerAktiv=false;
  if(weckFensterEnde!=null)getWindow().getDecorView().removeCallbacks(weckFensterEnde);
  anzeigeZuruecksetzen();
  setStatus("Anzeige normal – Weckfenster abgebrochen");
 }
 // Einstellungsabgleich ueber Supabase REST. Laeuft nativ, damit weder CORS
 // noch die CSP der Spielseite dazwischenfunken.
 private String supaRequest(String method,String path,String body) throws Exception {
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
  return b.toString();
 }
 private void anmeldenWennNoetig(WebView v){
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
 @Override public void onWindowFocusChanged(boolean f){super.onWindowFocusChanged(f);if(f)Fullscreen.apply(this);}
 @Override protected void onNewIntent(Intent in){
  super.onNewIntent(in); setIntent(in);
  // Nur die Sitzungsdaten auffrischen - die WebView bleibt unberuehrt,
  // sonst ginge die Anmeldung bei jedem Wechsel verloren.
  supaUrl=nz(in.getStringExtra("supaUrl")); supaKey=nz(in.getStringExtra("supaKey"));
  supaToken=nz(in.getStringExtra("supaToken")); supaTeam=nz(in.getStringExtra("supaTeam"));
  String a=nz(in.getStringExtra("accountId")); if(!a.isEmpty())gameAccountId=a;
  // Frueher lief der Weckermodus nur in onCreate. Existierte die Ansicht
  // bereits, kam onNewIntent dran und der Bildschirm blieb aus.
  weckerModus();
 }
 @Override protected void onResume(){super.onResume();Fullscreen.apply(this);OdinBubble.hide();restoreFromFloat();}
 @Override protected void onPause(){
  super.onPause();
  // Ohne flush() bleiben die Anmeldecookies nur im Speicher und sind nach
  // einem Neuaufbau des Prozesses weg.
  try{ android.webkit.CookieManager.getInstance().flush(); }catch(Exception ignored){}
  try{ if(webView!=null&&webView.getUrl()!=null)
        getSharedPreferences("odin",MODE_PRIVATE).edit()
          .putString("lastGameUrl",webView.getUrl()).apply(); }catch(Exception ignored){}
 }
 // Holt die WebView aus dem schwebenden Fenster zurueck in die Activity.
 // Wichtig: dieselbe Instanz, damit die Spielsitzung nicht neu laedt.
 private void restoreFromFloat(){
  if(!OdinFloat.active(gameAccountId))return;
  WebView w=OdinFloat.hide(gameAccountId);
  if(w==null||rootLayout==null)return;
  webView=w;
  runOnUiThread(()->{
   try{
    if(w.getParent() instanceof android.view.ViewGroup)
     ((android.view.ViewGroup)w.getParent()).removeView(w);
    // Vollbild wiederherstellen: Skalierung und Layoutgroesse zuruecksetzen,
    // sonst haengt die Seite verkleinert in der Ecke.
    w.setScaleX(1f); w.setScaleY(1f);
    w.setLayoutParams(new LinearLayout.LayoutParams(-1,0,1f));
    rootLayout.addView(w,1,new LinearLayout.LayoutParams(-1,0,1f));
    w.requestLayout(); w.invalidate();
    Intent i=new Intent(this,GameWebViewActivity.class);
    i.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT); startActivity(i);
    setStatus("zurueck im Vordergrund");
   }catch(Exception e){android.util.Log.e("ODIN_FLOAT","restore",e);}
  });
 }
 @Override public void onBackPressed(){
  if(dimDecke!=null){dimmenAus();return;}
  if(webView.canGoBack())webView.goBack();else super.onBackPressed();
 }
 private void minimizeToApp(){finish();}
 private class OdinNative{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public void status(String m){setStatus(m==null?"":m);}
  @JavascriptInterface public boolean syncReady(){ return !supaUrl.isEmpty()&&!supaToken.isEmpty()&&!gameAccountId.isEmpty(); }
  @JavascriptInterface public String settingsLoad(){
   try{
    if(!syncReady())return "{}";
    String q="godbot_settings?select=skey,value&account_id=eq."+java.net.URLEncoder.encode(gameAccountId,"UTF-8");
    String json=supaRequest("GET",q,null);
    org.json.JSONArray arr=new org.json.JSONArray(json);
    org.json.JSONObject out=new org.json.JSONObject();
    for(int i=0;i<arr.length();i++){org.json.JSONObject o=arr.getJSONObject(i);out.put(o.getString("skey"),o.getString("value"));}
    setStatus("Einstellungen geladen ("+out.length()+")");
    return out.toString();
   }catch(Exception e){ setStatus("Abgleich lesen fehlgeschlagen: "+e.getMessage()); return "{}"; }
  }
  // GodBot kann Meldungen an alle Geraete des Teams schicken - ohne Discord.
  @JavascriptInterface public boolean notify(String title,String body,String level){
   try{
    if(!syncReady())return false;
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
    setStatus("Einstellungen gesichert ("+rows.length()+")");
    return true;
   }catch(Exception e){ setStatus("Abgleich schreiben fehlgeschlagen: "+e.getMessage()); return false; }
  } @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setInstanceFollowRedirects(true);c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)throw new IOException("HTTP "+st);BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}
 private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}
}
EOF
printf '%s\n' "ODIN $VERSION · clean generator"
