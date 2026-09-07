# Teamzentrale Odin – Egress-Infrastruktur

Diese Komponente ist die serverseitige Grundlage für das Ziel, einen Spielaccount dauerhaft einem ausgehenden Netzwerkprofil zuzuordnen.

## Zielarchitektur

`Spielaccount -> Network Profile -> Egress Gateway -> feste öffentliche IP -> Zielserver`

Die WebApp speichert die Zuordnung des Spielaccounts zu einem `network_profile_id`. Die Egress-Schicht führt dazu eine eigene Gateway-Registry. Zugangsdaten und Proxy-Secrets bleiben ausschließlich serverseitig.

## Provider-unabhängig

Die WebApp wird nicht an Oracle, NordVPN oder einen anderen Anbieter gekoppelt. Ein Gateway erhält Provider, öffentliche IP, Status und technische Kennung als Metadaten. Dadurch können wir den Infrastruktur-Anbieter später austauschen, ohne die Accountverwaltung neu zu bauen.

## Sicherheitsprinzip

- Keine Provider- oder Gateway-Secrets im Browser.
- Die WebApp verwaltet nur Metadaten und Status.
- Keine offene Proxy-Funktionalität ohne Authentifizierung.
- Ein Gateway darf erst als aktiv gelten, wenn der Gateway selbst seinen Zustand bestätigt.

## Geplanter Transport

Für Endgeräte wird ein VPN-/Tunnel-Ansatz (z. B. WireGuard) gegenüber einem offenen HTTP-Proxy bevorzugt. So kann der relevante Spielverkehr über das Gateway geführt werden, ohne Gateway-Geheimnisse in der WebApp zu speichern.

## Feste IP – Realitätscheck

Eine dauerhaft kostenlose und uneingeschränkte Quelle für beliebig viele dedizierte öffentliche IPv4-Adressen gibt es nicht. Kostenlose Cloud-Angebote haben Limits, Kapazitätsgrenzen oder Nutzungsbedingungen. Deshalb bleibt die Egress-Schicht austauschbar.

## Nächster Infrastruktur-Schritt

1. Einen kleinen Gateway-Host mit fester öffentlicher IPv4 bereitstellen.
2. WireGuard bzw. einen vergleichbaren sicheren Tunnel konfigurieren.
3. Health-Check und sichere Gateway-Registrierung anbinden.
4. Einen einzelnen Test-Account über das Gateway routen.
5. Erst danach Account-spezifisches Routing und mehrere IPs untersuchen.

Ein normaler Browser auf iOS/Android kann seinen gesamten Traffic nicht allein durch eine WebApp auf diesen Gateway zwingen. Für den eigentlichen Spielverkehr brauchen wir deshalb eine klar definierte Client-/Tunnel-Lösung.

Die feste IP wird als stabile Netzwerkidentität behandelt und nicht als Mechanismus zur Umgehung von Bot-/Anti-Cheat-Systemen.
