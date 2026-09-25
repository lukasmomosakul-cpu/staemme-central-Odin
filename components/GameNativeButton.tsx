'use client';

import { useState } from 'react';
import { Browser } from '@capacitor/browser';
import { supabase } from '../lib/supabase';

declare global {
  interface Window {
    Android?: {
      openGame?: (accountId: string, username?: string, password?: string, scriptsJson?: string) => void;
      openGameWithAccounts?: (accountId: string, username?: string, accountsJson?: string) => void;
      openGameOnWorld?: (accountId: string, username?: string, accountsJson?: string, world?: string) => void;
      setGameCredentials?: (accountId: string, username: string, password: string) => void;
      hasGameCredentials?: (accountId: string) => boolean;
      setSupabaseSession?: (url: string, anonKey: string, accessToken: string, teamId: string, refreshToken?: string) => void;
    };
  }
}

type Props = { accountId: string; username?: string; world?: string; accounts?: { id?: string; name: string; world?: string; username?: string }[]; teamId?: string | null };
type ScriptEntry = { id:string; name:string; source:string; enabled:boolean; type:'Tampermonkey'|'Gist' };

const GAME_URL = 'https://www.die-staemme.de/';
// Odin PC: GodBot im PC-Browser mit Odin-Anbindung (Tampermonkey).
// Liegt im selben Gist wie GodBot, Quelle: pc/ im Repo.
const ODIN_PC_URL = 'https://gist.githubusercontent.com/lukasmomosakul-cpu/caadd6e90305d081454e1ca95e3397f6/raw/OdinPC.user.js';
const SCRIPTS_KEY = 'odin-script-library';

export default function GameNativeButton({ accountId, username = '', world = '', accounts = [], teamId = null }: Props) {
  const [pcHilfe, setPcHilfe] = useState(false);
  const openGame = async () => {
    localStorage.setItem('odin-selected-game-account', accountId);

    let scriptsJson = '[]';
    try {
      const rawScripts = localStorage.getItem(SCRIPTS_KEY);
      const scripts = rawScripts ? (JSON.parse(rawScripts) as ScriptEntry[]) : [];
      scriptsJson = JSON.stringify(
        scripts
          .filter((s) => s.enabled && /^https:\/\//i.test(s.source))
          .map((s) => ({ id:s.id, name:s.name, source:s.source, type:s.type }))
      );
    } catch {
      // Keep opening the game even if local settings cannot be read.
    }

    // Fussleiste im Spiel zeigt alle Accounts des Teams.
    // Mit ID: darueber wechselt die Fussleiste zwischen den Welten (1.87.0).
    const accountsJson = JSON.stringify(accounts.map((a) => ({ id: a.id ?? '', name: a.name, world: a.world ?? '', username: a.username ?? '' })));

    // Die Spielansicht hat keine eigene Supabase-Sitzung. Zugangstoken und Team
    // werden hier uebergeben, damit die GodBot-Einstellungen abgeglichen werden.
    try {
      if (window.Android?.setSupabaseSession && supabase && teamId) {
        const { data } = await supabase.auth.getSession();
        const token = data.session?.access_token ?? '';
        // Das Erneuerungstoken muss mit: der Zugangstoken gilt nur eine
        // Stunde. Ohne ihn lief die App danach in HTTP 401 - Einstellungen
        // und Meldungen wurden stundenlang nicht mehr geschrieben.
        const refresh = data.session?.refresh_token ?? '';
        if (token) {
          window.Android.setSupabaseSession(
            process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
            token,
            teamId,
            refresh,
          );
        }
      }
    } catch {
      // Ohne Sitzung laeuft das Spiel weiter, nur ohne Einstellungsabgleich.
    }

    // Welt vereinheitlichen: in der Datenbank steht oft nur die Zahl ("256"),
    // die Spielseite erwartet "de256". /page/play/256 liefert "invalid data".
    const welt = (() => {
      const x = (world ?? '').trim().toLowerCase().replace(/\s|welt/g, '');
      if (!x) return '';
      return /^[0-9]+$/.test(x) ? `de${x}` : x;
    })();

    // Direkt in die richtige Welt, damit die Anmeldung dort greift.
    if (window.Android?.openGameOnWorld) {
      window.Android.openGameOnWorld(accountId, username, accountsJson, welt);
      return;
    }
    if (window.Android?.openGameWithAccounts) {
      window.Android.openGameWithAccounts(accountId, username, accountsJson);
      return;
    }
    if (window.Android?.openGame) {
      // Kein Passwort: Anmeldung erfolgt bewusst manuell im Spiel.
      window.Android.openGame(accountId, username, '', scriptsJson);
      return;
    }

    // Im Browser (PC): keine App-Ansicht. Das Spiel laeuft im normalen
    // Tab, GodBot kommt ueber Odin PC (Tampermonkey) dazu.
    if (typeof window !== 'undefined' && !window.Android) {
      setPcHilfe(true);
      return;
    }
    await Browser.open({
      url: GAME_URL,
      toolbarColor: '#0b1020',
      presentationStyle: 'fullscreen',
    });
  };

  const welt = (world ?? '').trim().toLowerCase();
  return (
    <>
      <button type="button" className="iconButton" onClick={openGame} title="Die Stämme in Odin öffnen" aria-label="Die Stämme in Odin öffnen">
        🎮
      </button>
      {pcHilfe && (
        <div className="modalBackdrop" role="presentation" onMouseDown={() => setPcHilfe(false)}>
          <div className="modal" role="dialog" aria-modal="true" aria-labelledby="odinpc-title" onMouseDown={(e) => e.stopPropagation()} style={{ whiteSpace: 'normal' }}>
            <div className="modalHead">
              <div>
                <div className="eyebrow">{welt || 'Die Stämme'} · am PC</div>
                <h2 id="odinpc-title">Spielen mit Odin PC</h2>
              </div>
              <button type="button" className="iconButton" onClick={() => setPcHilfe(false)} aria-label="Schließen">×</button>
            </div>
            <div className="permissionNote" style={{ lineHeight: 1.6 }}>
              Im Browser läuft das Spiel im normalen Tab. <strong>Odin PC</strong> (Tampermonkey) bringt GodBot mit:
              Einstellungsabgleich mit der App, Befehle aus der Steuerzentrale, Geräte-Sperre und Protokoll.
            </div>
            <ol style={{ paddingLeft: 20, lineHeight: 1.7, fontSize: 14 }}>
              <li>Tampermonkey im Browser installieren (tampermonkey.net). In Chrome/Edge in den Erweiterungsdetails ggf. „Nutzerskripte zulassen“ bzw. den Entwicklermodus einschalten.</li>
              <li>„Odin PC installieren“ tippen und in Tampermonkey bestätigen.</li>
              <li>Ein vorhandenes Skript „GodBot“ in Tampermonkey <strong>deaktivieren</strong> – sonst läuft GodBot doppelt.</li>
              <li>Spiel öffnen, Welt betreten und unten links im Feld „Odin PC“ mit deinem Odin-Konto anmelden (einmal je Welt).</li>
            </ol>
            <div className="muted">Führt gerade die App dieses Konto, pausiert GodBot am PC. „Hier übernehmen“ holt ihn herüber.</div>
            <div className="modalActions">
              <button type="button" className="button secondary" onClick={() => window.open(ODIN_PC_URL, '_blank', 'noopener')}>Odin PC installieren</button>
              <button type="button" className="button" onClick={() => { window.open(GAME_URL, '_blank', 'noopener'); setPcHilfe(false); }}>Spiel öffnen</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
