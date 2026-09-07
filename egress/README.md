# Teamzentrale Odin – Egress-Infrastruktur

Diese Komponente ist die serverseitige Grundlage für das Ziel, einen Spielaccount dauerhaft einem ausgehenden Netzwerkprofil zuzuordnen.

## Zielarchitektur

`Spielaccount -> Network Profile -> Egress Gateway -> feste öffentliche IP -> Zielserver`

Die WebApp speichert bereits die Zuordnung des Spielaccounts zu einem `network_profile_id`. Die Egress-Schicht führt dazu eine eigene Gateway-Registry (`supabase/migrations/007_egress_nodes.sql`). Zugangsdaten und Proxy-Secrets bleiben ausschließlich serverseitig.

## Was jetzt vorhanden ist

- `egress/server.js`: kleiner Health-/Status-Dienst ohne zusätzliche Runtime-Abhängigkeiten.
- `/health`: öffentlicher, nicht-sensitiver Health-Check.
- `/status`: mit Bearer-Token geschützter Status-Check.
- `.env.example`: Konfiguration für Port, Gateway-Name und Secret.
- `egress_nodes`: Supabase-Tabelle für Gateway, Network Profile, Status und feste öffentliche IP.

## Feste IP

Eine feste öffentliche IPv4 lässt sich nicht durch Supabase, Vercel oder einen normalen Browser erzwingen. Dafür braucht der Egress-Host eine persistente öffentliche IPv4. Oracle Cloud dokumentiert reservierte öffentliche IPv4-Adressen, die auch nach Neustarts bzw. Redeployments am zugewiesenen privaten Interface erhalten bleiben. Die Always-Free-Compute-Ressourcen können dafür als günstiger Startpunkt dienen; Kapazität und Kontingente sind jedoch nicht garantiert. citeturn0search3turn0search0

## Sicherheitsgrenze

Der Dienst ist absichtlich **noch kein offener Proxy**. Zuerst wird ein einzelner Gateway-Host registriert und überwacht. Erst danach bauen wir die eigentliche Routing-Schicht für zugewiesene Network Profiles.

Ein normaler Browser auf iOS/Android kann seinen gesamten Traffic nicht einfach durch eine WebApp auf diesen Gateway zwingen. Für den eigentlichen Spielverkehr brauchen wir später eine klar definierte Client-/Proxy-Lösung. Die feste IP wird dabei als stabile Netzwerkidentität behandelt, nicht als Umgehung von Bot-/Anti-Cheat-Systemen.

## Start lokal

```bash
cd egress
cp .env.example .env
# GATEWAY_TOKEN in .env setzen
node server.js
```

Dann:

- `GET /health` → Health-Check
- `GET /status` mit `Authorization: Bearer <GATEWAY_TOKEN>` → geschützter Status
