'use client';

import { Browser } from '@capacitor/browser';

declare global {
  interface Window {
    Android?: {
      openGame?: (accountId: string) => void;
    };
  }
}

type Props = {
  accountId: string;
};

const GAME_URL = 'https://www.die-staemme.de/';

export default function GameNativeButton({ accountId }: Props) {
  const openGame = async () => {
    localStorage.setItem('odin-selected-game-account', accountId);

    // On Android, use Odin's native embedded WebView. This keeps the game
    // inside the app and gives us a place to inject Odin-managed scripts later.
    if (window.Android?.openGame) {
      window.Android.openGame(accountId);
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
