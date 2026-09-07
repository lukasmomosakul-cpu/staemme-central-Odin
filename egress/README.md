# Teamzentrale Odin – Egress-Infrastruktur

Diese Komponente ist die serverseitige Grundlage für das Ziel, einen Spielaccount dauerhaft einem ausgehenden Netzwerkprofil zuzuordnen.

## Zielarchitektur

`Spielaccount -> Network Profile -> Egress Gateway -> öffentliche IP -> Zielserver`

Die WebApp speichert bereits die Zuordnung des Spielaccounts zu einem `network_profile_id`. Der Egress-Gateway darf diese Zuordnung später serverseitig auswerten; niemals dürfen Zugangsdaten oder Proxy-Secrets im Browser landen.

## Wichtiger Punkt zur festen IP

Eine feste öffentliche IPv4 lässt sich nicht durch Supabase/Vercel oder einen Browser erzwingen. Für eine wirklich feste Quell-IP braucht jedes Egress-Gateway eine statische öffentliche IP bzw. einen Provider, der diese garantiert. Mehrere unterschiedliche feste IPs benötigen entsprechend mehrere Egress-Endpunkte oder einen Provider mit mehreren reservierten Adressen.

## Geplanter Gateway

Für die erste Version wird ein kleiner Linux-Gateway-Host vorgesehen. Er soll:

1. nur ausgehend Verbindungen für zugewiesene Accounts erlauben,
2. pro Network Profile eine definierte Egress-IP verwenden,
3. keine geheimen Zugangsdaten an die Next.js-App liefern,
4. Health-Checks bereitstellen,
5. Logs ohne Spielpasswörter oder Session-Cookies führen.

Die eigentliche Proxy-/Routing-Implementierung wird erst aktiviert, wenn der konkrete Hosting-Anbieter und die verfügbaren statischen IPs feststehen.

## Sicherheitsgrenze

Die Egress-Schicht ist **kein Ersatz für eine Browser-Erweiterung oder einen lokalen Client**. Ein normaler Browser auf iOS/Android kann seinen gesamten Traffic nicht einfach über diesen Gateway zwingen. Für den eigentlichen Spielverkehr brauchen wir daher später eine klar definierte Client-/Proxy-Lösung.
