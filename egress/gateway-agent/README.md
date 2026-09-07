# Odin Gateway Agent

Der Gateway-Agent ist die serverseitige Komponente zwischen Odin und einem externen Egress-Host.

## Übergangsbetrieb

Bis die Egress-Infrastruktur produktiv ist, verbindet sich jeder Spieler direkt mit Die Stämme über seine normale Internet-IP. Odin speichert bereits die gewünschte Network-Profile-Zuordnung, routet den Spielverkehr aber noch nicht über einen Gateway.

## Read-only Spielintegration

Die erste Spielintegration läuft als Tampermonkey-Bridge im Browser und ist bewusst **read-only**. Sie kann sichtbare Spielinformationen melden: Welt, Spielaccount, Dörfer, Session-Status, Angriffsereignisse und Botschutz-Signale.

Spielpasswörter werden nicht an Odin übertragen oder gespeichert. Die Bridge soll keine Captchas, Botschutz-Mechanismen oder andere Schutzmaßnahmen umgehen. Automatisierung wird erst nach einer separaten Prüfung der Spielregeln und mit klaren Sicherheitsgrenzen umgesetzt.

## Zielarchitektur

`Spielbrowser -> read-only Tampermonkey Bridge -> Odin Integration API -> Team-Dashboard`

und später:

`Spielaccount -> Network Profile -> Egress Node -> öffentliche IP`

## Gateway-Sicherheit

- Keine privaten Schlüssel in GitHub, Supabase oder Vercel speichern.
- Kein offener HTTP/SOCKS-Proxy.
- Gateway-API authentifizieren und TLS-geschützt betreiben.
- Nur notwendige Betriebsdaten an Odin melden.
