'use client';

import { Browser } from '@capacitor/browser';

declare global {
  interface Window {
    Android?: {
      openGame?: (accountId: string, username?: string, password?: string) => void;
    };
  }
}

type Props = {
  accountId: string;
};

const GAME_URL = 'https://www.die-staemme.de/';
const CREDENTIALS_KEY = 'odin-game-credentials';

type Credential = { username: string; password: string };

export default function GameNativeButton({ accountId }: Props) {
  const openGame = async () => {
    localStorage.setItem('odin-selected-game-account', accountId);

    let username = '';
    let password = '';
    try {
      const raw = localStorage.getItem(CREDENTIALS_KEY);
      const credentials = raw ? (JSON.parse(raw) as Record<string, Credential>) : {};
      username = credentials[accountId]?.username ?? '';
      password = credentials[accountId]?.password ?? '';
    } catch {
      // Keep opening the game even if saved credentials cannot be read.
    }

    // On Android, use Odin's native embedded WebView. Credentials are passed
    // only to the local native activity so it can prefill the game login form.
    if (window.Android?.openGame) {
      window.Android.openGame(accountId, username, password);
      return;
    }

    // Keep the web/PWA version usable in a normal browser.
    await Browser.open({
      url: GAME_URL,
      toolbarColor: '#0b1020',
      presentationStyle: 'fullscreen',
    });
  };

  return (
    <button
      type="button"
      className="iconButton"
      onClick={openGame}
      title="Die Stämme in Odin öffnen"
      aria-label="Die Stämme in Odin öffnen"
    >
      🎮
    </button>
  );
}
