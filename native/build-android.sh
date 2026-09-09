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
    <uses-sdk android:minSdkVersion="26" />
    <application android:theme="@style/AppTheme" android:label="Odin" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true"><intent-filter><action android:name="android.intent.action.MAIN" /><category android:name="android.intent.category.LAUNCHER" /></intent-filter></activity>
        <activity android:name=".GameWebViewActivity" android:exported="false" />
    </application>
</manifest>
EOF
cat > "$APP/src/main/res/values/styles.xml" <<'EOF'
<resources><style name="AppTheme" parent="@android:style/Theme.Material.Light.NoActionBar"><item name="android:fontFamily">sans</item><item name="android:colorAccent">#333333</item><item name="android:navigationBarColor">#ffffff</item><item name="android:statusBarColor">#ffffff</item><item name="android:windowLightStatusBar">true</item></style></resources>
EOF
cat > "$JAVA_DIR/MainActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.Activity; import android.content.Intent; import android.os.Bundle;
public class MainActivity { @Override protected void onCreate(Bundle b){ super.onCreate(b); startActivity(new Intent(this,GameWebViewActivity.class)); finish(); } }
EOF
cat > "$JAVA_DIR/MainActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.app.Activity; import android.content.Intent; import android.os.Bundle;
public class MainActivity extends Activity { @Override protected void onCreate(Bundle b){ super.onCreate(b); startActivity(new Intent(this,GameWebViewActivity.class)); finish(); } }
EOF
cat > "$JAVA_DIR/GameWebViewActivity.java" <<'EOF'
package de.teamzentrale.odin;
import android.annotation.SuppressLint; import android.app.Activity; import android.os.Bundle; import android.webkit.*; import android.widget.FrameLayout; import android.util.Log; import android.webkit.JavascriptInterface; import java.io.*; import java.net.*; import org.json.JSONObject;
public class GameWebViewActivity {
 private WebView webView;
 @SuppressLint("SetJavaScriptEnabled") @Override protected void onCreate(Bundle b){super.onCreate(b);FrameLayout root=new FrameLayout(this);webView=new WebView(this);root.addView(webView,new FrameLayout.LayoutParams(-1,-1));setContentView(root);WebSettings s=webView.getSettings();s.setJavaScriptEnabled(true);s.setDomStorageEnabled(true);s.setDatabaseEnabled(true);android.webkit.CookieManager.getInstance().setAcceptCookie(true);android.webkit.CookieManager.getInstance().setAcceptThirdPartyCookies(webView,true);webView.setWebChromeClient(new WebChromeClient(){@Override public boolean onConsoleMessage(ConsoleMessage m){Log.d("ODIN_JS",m.message()+" @"+m.lineNumber()+" "+m.sourceId());return true;}});webView.addJavascriptInterface(new OdinNative(),"OdinNative");webView.setWebViewClient(new WebViewClient(){@Override public boolean shouldOverrideUrlLoading(WebView v,WebResourceRequest r){return false;}@Override public void onPageFinished(WebView v,String u){injectManagedScripts(v);loadEnabledScripts(v);}});webView.loadUrl("https://www.die-staemme.de/");}
 private void injectManagedScripts(WebView v){try{BufferedReader r=new BufferedReader(new InputStreamReader(getAssets().open("game-scripts.js")));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append('\n');r.close();v.evaluateJavascript(b.toString(),null);}catch(Exception e){Log.e("ODIN","bootstrap",e);}}
 private void loadEnabledScripts(WebView v){ }
 private void executeGodBotWhenReady(WebView v){ }
 private void injectGodBot(WebView v){ }
 @Override public void onBackPressed(){if(webView.canGoBack())webView.goBack();else super.onBackPressed();}
 private void minimizeToApp(){finish();}
 private class OdinNative{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());} @JavascriptInterface public String httpGet(String u){try{HttpURLConnection c=(HttpURLConnection)new URL(u).openConnection();c.setRequestMethod("GET");c.setConnectTimeout(15000);c.setReadTimeout(30000);c.setRequestProperty("User-Agent","Mozilla/5.0 (Android) Odin");int st=c.getResponseCode();InputStream in=(st>=200&&st<400)?c.getInputStream():c.getErrorStream();if(in==null)throw new IOException("HTTP "+st);BufferedReader r=new BufferedReader(new InputStreamReader(in));StringBuilder b=new StringBuilder();String l;while((l=r.readLine())!=null)b.append(l).append("\n");r.close();if(st<200||st>=400)throw new IOException("HTTP "+st);return b.toString();}catch(Exception e){throw new RuntimeException(e);}}}
 private class OdinBridge{@JavascriptInterface public void minimize(){runOnUiThread(()->minimizeToApp());}}
}
EOF
printf '%s\n' "ODIN $VERSION · clean generator"
