'use client';

import { useState } from 'react';

type Props = {
  url: string;
  username?: string;
  password?: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openGame = async () => {
    setBusy(true);
    try {
      const native = typeof window !== 'undefined' && 'Capacitor' in window;

      // In the Android app we deliberately navigate the existing WebView to the game.
      // This is the most reliable way to keep Die Stämme inside Odin and avoids
      // version-dependent behavior of external browser plugins.
      if (native) {
        window.location.assign(url);
        return;
      }

      window.open(url, '_blank', 'noopener,noreferrer');
    } catch {
      onFallback?.();
      try {
        window.open(url, '_blank', 'noopener,noreferrer');
      } catch {
        // Nothing else to do here.
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      className="gameIconButton"
      onClick={openGame}
      disabled={busy}
      title="Die Stämme öffnen"
      aria-label="Die Stämme öffnen"
    >
      {busy ? '…' : '🎮'}
    </button>
  );
}
