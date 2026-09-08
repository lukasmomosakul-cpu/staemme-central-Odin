# Stämme Central — Odin — MASTER BACKUP

Stand: 08.09.2026

## Git
- Repository: `lukasmomosakul-cpu/staemme-central-Odin`
- Branch: `main`
- Aktueller Stand: `0564e8102d91d524375c3df70506682670d18df4`
- Letzter Commit: `Remove duplicate header version display`

## Architektur
- Next.js WebApp / PWA als Odin-Oberfläche.
- Supabase ist mit der App verbunden und dient als zentrale persistente Datenbasis.
- Vercel hostet die WebApp.
- GitHub enthält Quellcode und Android-Build-Workflow.
- Android-App lädt die Vercel-Produktionsoberfläche.
- Die Stämme wird in der Android-App über einen nativen Android-WebView innerhalb von Odin geöffnet, nicht mehr über einen externen Browser/Chrome.

## Die Stämme
- Spiel läuft innerhalb der Android-App.
- JavaScript und DOM-Storage sind im WebView aktiviert.
- Cookies/Third-Party-Cookies sind für die Spielsession freigegeben.
- Ziel: Odin-Funktionen neben bzw. oberhalb des Spiel-WebViews nutzbar machen und Spielansicht temporär minimieren/zurückstellen.

## Login
- Odin-Login über Supabase funktioniert.
- Für den Die-Stämme-Account werden Zugangsdaten in Odin verwaltet.
- Passwort soll nicht unverschlüsselt in Supabase gespeichert werden.
- Benutzername und Passwort sollen beim Öffnen der Spielansicht automatisch in die Die-Stämme-Loginmaske eingesetzt werden.
- Aktueller bekannter Fehler: Der Passwortwert wird zuverlässig eingesetzt, der Accountname war zuletzt noch nicht zuverlässig.
- Das Ausfüllen muss nach tatsächlichem Laden/dynamischem Erzeugen der Loginfelder erfolgen.

## Script-System
- Es existiert eine zentrale Scriptverwaltung in Odin.
- Scripts sollen nicht nur lokal in `localStorage` liegen, sondern team-/benutzerbezogen über Supabase persistiert werden.
- GodBot ist als Script hinterlegt und soll automatisch im Spiel-WebView geladen werden.
- Native WebView besitzt eine Script-Injection-Schicht.
- Scripts dürfen NICHT bereits auf der Die-Stämme-Loginseite ausgeführt werden.
- GodBot soll erst auf der eigentlichen Spielwelt/Spielseite ausgeführt werden.
- Aktueller bekannter Fehler: GodBot wurde zuletzt trotz Loader weiterhin nicht sichtbar/aktiv im Spiel ausgeführt; dieser Punkt ist noch offen und muss gezielt debuggt werden.
- GodBot selbst liegt extern als Gist und besitzt eine eigene, vom Nutzer eingebaute Passwortsperre. Diese Sperre soll in Odin nicht auf der Loginseite erscheinen. Die Sperrlogik soll auf der eigentlichen Welt weiterhin berücksichtigt werden, sofern sie nicht ausdrücklich für die App deaktiviert wird.

## Versionierung
- App-Version soll sichtbar oben rechts in der Kopfzeile stehen.
- Die doppelte Versionsanzeige wurde zuletzt korrigiert; die Anzeige direkt neben dem Anmeldebutton wurde entfernt.
- Letzter bekannter App-Stand: `v0.10.0`.

## Supabase
- Projekt-ID: `sjrcoomhuuahayztzdgc`
- Supabase ist als Plugin/Integration verbunden.
- Tabellen/Migrationen für Spielaccounts bzw. Scriptverwaltung wurden angelegt bzw. vorbereitet.
- RLS ist für die team-/benutzerbezogenen Scriptdaten vorgesehen.

## Android Build
- Workflow: `.github/workflows/android-debug.yml`
- Debug-APK wird über GitHub Actions gebaut.
- Artifact war zuletzt `teamzentrale-odin-debug-apk`.
- GitHub liefert das Artifact als ZIP; darin befindet sich die APK.
- Ein wiederkehrendes Nutzerproblem war die Meldung beim Entpacken, dass die Datei bereits vorhanden sei.
- Ziel für den nächsten Build: eindeutig versioniertes APK-Artifact bzw. möglichst direkte APK-Ausgabe, damit alte Builds nicht verwechselt werden.

## Aktuelle offene Aufgaben
1. Android-Build/Artifact zuverlässig verifizieren.
2. Versionierung weiter sichtbar halten, damit sofort erkannt wird, welche APK installiert ist.
3. Die-Stämme-Accountname beim Login zuverlässig einsetzen.
4. GodBot zuverlässig erst nach erfolgreichem Eintritt in eine Spielwelt laden.
5. GodBot-Kompatibilität mit Tampermonkey-Funktionen (`GM_*`, `@grant`, `@require` etc.) prüfen, falls der direkte Script-Loader nicht genügt.
6. Sichere persistente Speicherung der sensiblen Die-Stämme-Zugangsdaten über Android Secure Storage/Keystore planen; Supabase nicht als Klartext-Passwortspeicher verwenden.
7. Odin-Spielansicht später um minimierbares/restorebares Browserfenster erweitern.

## Wichtige Grundregel für weitere Änderungen
Nicht blind mehrere Dinge gleichzeitig ändern. Erst aktuellen Commit/Build verifizieren, dann eine einzelne Ursache beheben und anschließend einen eindeutig identifizierbaren Build erzeugen.
