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

## Odin-Anbindung (seit GodBot v529 / Odin 1.67.0)
GodBot spricht die App ausdrücklich an (`window.Odin`, bereitgestellt vom Bootstrap
in `native/patch-godbot-loader.sh`):

| Aufruf | Wirkung in der App |
|---|---|
| `Odin.lebt()` | Lebenszeichen, alle 5 s aus `runJobScheduler` – auch bei Botschutz |
| `Odin.termin(schluessel, art, ms)` | Planungszeitpunkt sofort an den Dienst (ms ≤ 0 löscht) |
| `Odin.protokoll(text)` | Zeile ins App-Protokoll |

Der Dienst weckt erneut, wenn ein Termin > 3 Min überfällig ist und GodBot seitdem
kein Lebenszeichen gab (alle 5 Min, höchstens 1 h). Im Dimm-Modus lädt die Ansicht
die Seite neu, wenn GodBot > 5 Min schweigt.

Im Browser fehlt `window.Odin`; GodBot nutzt dann einen Platzhalter, der nichts tut.
Seit v529 gilt `@grant none`: GodBot läuft im Seitenkontext, die früheren
Sandbox-Brücken (`unsafeWindow`, Getter für `game_data` usw.) sind entfernt.
