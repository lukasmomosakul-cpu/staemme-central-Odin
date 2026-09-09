#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/app"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
PKG="de.teamzentrale.odin"
JAVA_DIR="$APP/src/main/java/de/teamzentrale/odin"
mkdir -p "$JAVA_DIR" "$APP/src/main/assets"

cat > "$APP/build.gradle" <<'EOF'
plugins {
    id 'com.android.application'
}

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
            def ks = System.getenv('ODIN_KEYSTORE_FILE')
            if (ks != null) {
                storeFile file(ks)
                storePassword System.getenv('ODIN_KEYSTORE_PASSWORD')
                keyAlias System.getenv('ODIN_KEY_ALIAS')
                keyPassword System.getenv('ODIN_KEY_PASSWORD')
            }
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
import re, sys
p=Path(sys.argv[1]); v=sys.argv[2]
a=v.split('.')
code=int(a[0])*1000000+int(a[1])*1000+int(a[2])
s=p.read_text()
s=re.sub(r'\bversionCode\s+\d+', f'versionCode {code}', s, count=1)
s=re.sub(r"versionName\s+['\"][^'\"]+['\"]", f"versionName '{v}'", s, count=1)
p.write_text(s)
PY

cat > "$APP/src/main/AndroidManifest.xml" <<'EOF'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
    <uses-sdk android:minSdkVersion="26" />
    <application android:theme="@style/AppTheme" android:label="Odin" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <activity android:name=".GameWebViewActivity" android:exported="false" />
    </application>
</manifest>
EOF

mkdir -p "$APP/src/main/res/values"
cat > "$APP/src/main/res/values/styles.xml" <<'EOF'
<resources>
    <style name="AppTheme" parent="android:style/Theme.Material.Light.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:colorAccent">#333333</item>
        <item name="android:navigationBarColor">#ffffff</item>
        <item name="android:statusBarColor">#ffffff</item>
        <item name="android:windowLightStatusBar">true</item>
    </style>
</resources>
EOF

cat > "$JAVA_DIR/MainActivity.java" <<'EOF'
package de.teamzentrale.odin;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

public class MainActivity extends Activity {
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        startActivity(new Intent(this, GameWebViewActivity.class));
        finish();
    }
}
EOF

cat > "$JAVA_DIR/GameWebViewActivity.java" <<'EOF'
package de.teamzentrale.odin;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.os.Bundle;
import android.webkit.CookieManager;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.view.ViewGroup;
import android.widget.FrameLayout;

public class GameWebViewActivity extends Activity {
    private WebView webView;

    @SuppressLint("SetJavaScriptEnabled")
    @Override protected void onCreate(Bundle b) {
        super.onCreate(b);
        FrameLayout root = new FrameLayout(this);
        webView = new WebView(this);
        root.addView(webView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        setContentView(root);

        WebSettings s = webView.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setDatabaseEnabled(true);
        s.setBuiltInZoomControls(false);
        s.setDisplayZoomControls(false);
        s.setUserAgentString(s.getUserAgentString() + " Odin");
        CookieManager.getInstance().setAcceptCookie(true);
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
        webView.setWebChromeClient(new WebChromeClient());
        webView.addJavascriptInterface(new OdinNative(), "OdinNative");
        webView.setWebViewClient(new WebViewClient() {
            @Override public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest r) { return false; }
            @Override public void onPageFinished(WebView v, String url) {
                super.onPageFinished(v, url);
                injectManagedScripts(v);
                loadEnabledScripts(v);
            }
        });
        webView.loadUrl("https://www.die-staemme.de/");
    }

    private void injectManagedScripts(WebView v) {
        try {
            java.io.BufferedReader r = new java.io.BufferedReader(new java.io.InputStreamReader(getAssets().open("game-scripts.js")));
            StringBuilder b = new StringBuilder(); String l;
            while ((l = r.readLine()) != null) b.append(l).append('\n'); r.close();
            v.evaluateJavascript(b.toString(), null);
        } catch (Exception ignored) {}
    }

    private void loadEnabledScripts(WebView v) {
        String u = v.getUrl() == null ? "" : v.getUrl();
        if (!u.matches("(?i).*[/]game[.]php(?:[?].*)?$")) return;
        try {
            java.io.BufferedReader r = new java.io.BufferedReader(new java.io.InputStreamReader(getAssets().open("godbot.user.js")));
            StringBuilder b = new StringBuilder(); String l;
            while ((l = r.readLine()) != null) b.append(l).append('\n'); r.close();
            String src = b.toString();
            if (!src.trim().isEmpty()) v.evaluateJavascript("try{(0,eval)(" + android.webkit.ValueCallback.class.getName() + ");(0,eval)(" + org.json.JSONObject.quote(src) + ")}catch(e){console.error(e)}", null);
        } catch (Exception e) { android.util.Log.e("ODIN_GODBOT", "load_failed", e); }
    }

    private class OdinNative {
        @JavascriptInterface public void minimize() { runOnUiThread(() -> finish()); }
    }
}
EOF

printf '%s\n' "native/build-android.sh: clean generator ready for ODIN $VERSION"
