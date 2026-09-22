# GodBot – fest in Odin eingebaut

`GodBot.user.js` ist die maßgebliche Quelle. Der Android-Build legt sie
unverändert als Asset in die APK (`native/patch-godbot-loader.sh`). Zur Laufzeit
wird nichts aus dem Gist geholt.

## Neue GodBot-Fassung
1. Patch wie gewohnt (`rep()`, `node --check`, Bereichsprüfung, Funktionsnamen-Diff,
   Bare-LF-Zahl = 0 – die Datei ist CRLF).
2. `@version` im Kopf erhöhen.
3. Datei hier ersetzen **und** `VERSION` des Repos erhöhen – ein Commit.
4. CI baut die APK; die App meldet beim ersten Laden „GodBot: vALT → vNEU“.

Der Gist (`caadd6e90305d081454e1ca95e3397f6`) bleibt bestehen und wird weiter
gepflegt (Tampermonkey im Browser). Die App liest ihn nur nicht mehr zur Laufzeit.

## Zusatzskripte
Tampermonkey-Skripte aus der Skriptverwaltung laufen nach GodBot, jedes in einer
eigenen Funktion. Beachtet werden `@match`, `@include`, `@exclude`,
`@exclude-match` und `@require` (eine Stunde zwischengespeichert).
