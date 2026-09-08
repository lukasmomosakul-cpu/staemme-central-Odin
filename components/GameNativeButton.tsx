'use client';

import { Browser } from '@capacitor/browser';

declare global {
  interface Window {
    Android?: {
      openGame?: (accountId: string, username?: string, password?: string, scriptsJson?: string) => void;
    };
  }
}

type Props = { accountId: string };
type Credential = { username: string; password: string };
type ScriptEntry = { id:string; name:string; source:string; enabled:boolean; type:'Tampermonkey'|'Gist' };

const GAME_URL = 'https://www.die-staemme.de/';
const CREDENTIALS_KEY = 'odin-game-credentials';
const SCRIPTS_KEY = 'odin-script-library';

export default function GameNativeButton({ accountId }: Props) {
  const openGame = async () => {
    localStorage.setItem('odin-selected-game-account', accountId);

    let username = '';
    let password = '';
    let scriptsJson = '[]';
    try {
      const rawCredentials = localStorage.getItem(CREDENTIALS_KEY);
      const credentials = rawCredentials ? (JSON.parse(rawCredentials) as Record<string, Credential>) : {};
      username = credentials[accountId]?.username ?? '';
      password = credentials[accountId]?.password ?? '';

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

    if (window.Android?.openGame) {
      window.Android.openGame(accountId, username, password, scriptsJson);
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
