'use client';

import { useState } from 'react';

type Props = {
  url: string;
  username?: string;
  password?: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url }: Props) {
  const [busy, setBusy] = useState(false);

  const openGame = () => {
    setBusy(true);
    // Deliberately use the app's own WebView. This avoids any custom Capacitor
    // plugin and therefore cannot fall back to an external browser or the old
    // GameWebView plugin.
    window.location.assign(url);
  };

  return (
    <button
      type="button"
      className="gameIconButton"
      onClick={openGame}
      disabled={busy}
      title="Die Stämme in Odin öffnen"
      aria-label="Die Stämme in Odin öffnen"
    >
      {busy ? '…' : '🎮'}
    </button>
  );
}
