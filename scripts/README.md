# Teamzentrale Odin – Spielinhalte Bridge

Die Spielanbindung wird zunächst **read-only** aufgebaut. Ziel ist, aus einer bereits im Browser geöffneten Die-Staemme-Seite sichtbare, nicht-sensitive Spieldaten an Odin zu melden, z. B. Welt, aktuelle Seite, Dorf-ID und erkannte Ereignisse.

## Sicherheitsprinzipien

- Keine Spielpasswörter oder Session-Cookies an Odin senden.
- Keine automatischen Klicks, Befehle, Käufe oder Aktionen im Spiel.
- Keine Zugangsdaten in GitHub, Vercel oder Supabase speichern.
- Die Browser-Erweiterung/userscript sendet ausschließlich explizit definierte Telemetriedaten.
- Das Bridge-Token wird pro Spielaccount erzeugt und kann später widerrufen werden.

## Geplanter Datenfluss

`Die-Staemme-Browserseite → read-only Bridge → Supabase RPC → Spielaccount → Odin Dashboard`

Damit können wir zuerst beweisen, dass Odin echte Spielinhalte empfängt, bevor wir Angriffserkennung, Botschutz-Hinweise und Benachrichtigungen live anbinden.

## Aktueller Stand

Die Datenbankmigration `008_game_bridge.sql` legt die sichere Bridge-Struktur und die RPC-Funktion `ingest_game_telemetry` an. Als nächstes wird die Browser-Bridge an die konkrete Spielseitenstruktur angepasst und im Dashboard ein Live-Verbindungsstatus angezeigt.
