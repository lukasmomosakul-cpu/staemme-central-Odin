# Stämme Central — Odin

Team-Zentrale für die Verwaltung von Spielaccounts, Teammitgliedern, Geräten, Events, Scripts und Netzwerkprofilen.

## MVP
- Team & Rollen: Owner, Admin, Player, Observer
- Spielaccounts und Geräte
- Live-Status/Event-Modell
- Angriffs- und Botschutz-Hinweise
- zentrale Script-/Einstellungsverwaltung
- NetworkProfile/Egress-Abstraktion für eine spätere, regelkonforme Netzwerkintegration
- mobile WebApp/PWA als Ziel

## Start
```bash
pnpm install
pnpm dev
```

Die Netzwerk-Schicht ist bewusst getrennt von der Spiel- und UI-Logik und nicht als Umgehung von Sperren, Accountlimits oder Botschutz gedacht.
