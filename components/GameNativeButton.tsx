'use client';

import { Browser } from '@capacitor/browser';

type Props = {
  accountId: string;
};

const GAME_URL = 'https://www.die-staemme.de/';

export default function GameNativeButton({ accountId }: Props) {
  const openGame = async () => {
    localStorage.setItem('odin-selected-game-account', accountId);

    // Capacitor Browser opens Die Stämme in an Android Custom Tab instead of
    // handing the URL to the external browser app. This gives the game its
    // own first-party browser context while keeping Odin underneath; pressing
    // Back/Close returns directly to the Odin app.
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
      title="Die Stämme in der App öffnen"
      aria-label="Die Stämme in der App öffnen"
    >
      🎮
    </button>
  );
}
