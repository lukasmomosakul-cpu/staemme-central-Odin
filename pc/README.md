# Odin PC

GodBot im PC-Browser (Tampermonkey), verbunden mit Odin wie ein weiteres Gerät.

- **Quelle:** `pc/odin-pc.js` (Schicht) + Loader aus `native/patch-godbot-loader.sh` + `godbot/GodBot.user.js`
- **Bauen:** `python3 pc/build_odin_pc.py` → `pc/OdinPC.user.js` (nicht eingecheckt)
- **Verteilen:** als `OdinPC.user.js` in den GodBot-Gist (`caadd6e90305d081454e1ca95e3397f6`), per PATCH nur diese Datei, danach `size` gegen die lokale Bytezahl prüfen.
- **Version:** `<GodBot-Version>.<PC_REV>` – nach jedem GodBot-Release neu bauen und hochladen, `PC_REV` bei Änderungen an der Schicht erhöhen.

Was die Schicht macht: Anmeldung mit dem Odin-Konto (Supabase, einmal je Welt), Zuordnung Welt + Spielername → `game_accounts`, Geräte-Sperre `lease_holen`/`lease_freigeben` (017), ein Tab je Welt (BroadcastChannel), `OdinNative` als JS-Nachbau (Abgleich `godbot_settings`, `godbot_befehle`, `notifications`, `app_events` mit `bereich = <b>/pc-<instanz>`). Kein Wecken – der Tab muss offen sein.
