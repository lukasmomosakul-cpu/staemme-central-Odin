# Odin Gateway Agent

Der Gateway-Agent ist die serverseitige Komponente zwischen Odin und einem eigenen Egress-Host.

## Ziel

`Endgerät -> WireGuard -> Odin Gateway -> Internet`

Die WebApp kennt dabei nur den Gateway-Status und die Zuordnung. Private WireGuard-Schlüssel bleiben ausschließlich auf Gateway und Endgerät.

## Sicherheitsregeln

- Keine privaten Schlüssel in GitHub, Supabase oder Vercel speichern.
- Keine Spielpasswörter im Gateway-Agent speichern.
- Kein offener HTTP/SOCKS-Proxy.
- Der Status-Endpunkt darf nur minimale Betriebsdaten liefern.
- Für Produktion muss der Agent authentifiziert und TLS-geschützt betrieben werden.

## Erste Testphase

1. Einen eigenen Linux-Rechner/Server als Gateway verwenden.
2. WireGuard installieren und als VPN-Gateway konfigurieren.
3. IP-Forwarding und NAT aktivieren.
4. Auf dem Client die WireGuard-Konfiguration importieren.
5. Eine öffentliche IP prüfen.
6. Erst danach das Gateway in `egress_nodes` registrieren.

Die konkrete Gateway-Konfiguration hängt vom vorhandenen Internetanschluss und dessen öffentlicher IP ab. Diese Datei enthält absichtlich keine geheimen Schlüssel oder Beispiel-Credentials.
