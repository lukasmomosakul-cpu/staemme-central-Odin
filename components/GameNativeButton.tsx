'use client';

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
      setSupabaseSession?: (url: string, anonKey: string, accessToken: string, teamId: string) => void;
    };
  }
}

type Props = { accountId: string; username?: string; world?: string; accounts?: { name: string; world?: string }[]; teamId?: string | null };
type ScriptEntry = { id:string; name:string; source:string; enabled:boolean; type:'Tampermonkey'|'Gist' };

const GAME_URL = 'https://www.die-staemme.de/';
const SCRIPTS_KEY = 'odin-script-library';

export default function GameNativeButton({ accountId, username = '', world = '', accounts = [], teamId = null }: Props) {
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
    const accountsJson = JSON.stringify(accounts.map((a) => ({ name: a.name, world: a.world ?? '' })));

    // Die Spielansicht hat keine eigene Supabase-Sitzung. Zugangstoken und Team
    // werden hier uebergeben, damit die GodBot-Einstellungen abgeglichen werden.
    try {
      if (window.Android?.setSupabaseSession && supabase && teamId) {
        const { data } = await supabase.auth.getSession();
        const token = data.session?.access_token ?? '';
        if (token) {
          window.Android.setSupabaseSession(
            process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
            process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
            token,
            teamId,
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

    await Browser.open({
      url: GAME_URL,
      toolbarColor: '#0b1020',
      presentationStyle: 'fullscreen',
    });
  };

  return (
    <button type="button" className="iconButton" onClick={openGame} title="Die Stämme in Odin öffnen" aria-label="Die Stämme in Odin öffnen">
      🎮
    </button>
  );
}
