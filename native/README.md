# Teamzentrale Odin – native App-Hülle

Die native Hülle nutzt Capacitor und lädt die bestehende Odin-WebApp innerhalb der nativen WebView. Dadurch ist die Spielansicht nicht mehr von einem Cross-Origin-iframe abhängig.

## Entwicklungsablauf

1. Node.js und pnpm installieren.
2. Abhängigkeiten installieren: `pnpm install`
3. Odin-WebApp für die native Hülle bereitstellen und `ODIN_NATIVE_SERVER_URL` auf die HTTPS-URL setzen.
4. Capacitor synchronisieren: `pnpm cap:sync`
5. Für Android: Android Studio öffnen und das Android-Projekt bauen.
6. Für iOS: auf macOS mit Xcode das iOS-Projekt bauen/signieren.

Die native Hülle übernimmt nicht die Zugangsdaten des Spiels. Die Spielseite läuft in der nativen WebView und verwaltet ihre eigene Sitzung.

## Wichtige Grenze

Die native Hülle garantiert nicht, dass der Spielbetreiber jede Form von eingebetteter/automatisierter Nutzung akzeptiert. Sie umgeht keine Captchas, Bot-Schutzmaßnahmen, Cookie-Schutzmechanismen oder andere Serverregeln.

## Späteres Egress

Die Hülle bleibt unabhängig vom Egress-Layer. Später kann die Verbindung pro Spielaccount über ein serverseitiges Gateway geführt werden, ohne die App-Struktur neu zu bauen.
