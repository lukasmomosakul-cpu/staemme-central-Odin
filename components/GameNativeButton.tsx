'use client';

import { useState } from 'react';

type Props = {
  url: string;
  username?: string;
  password?: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url, username, password, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openGame = async () => {
    setBusy(true);
    try {
      const native = typeof window !== 'undefined' && 'Capacitor' in window;

      if (native) {
        const { registerPlugin } = await import('@capacitor/core');
        const GameWebView = registerPlugin<{
          open: (options: { url: string; username?: string; password?: string }) => Promise<void>;
        }>('GameWebView');
        await GameWebView.open({ url, username, password });
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
      title="Die Stämme in Odin öffnen"
      aria-label="Die Stämme in Odin öffnen"
    >
      {busy ? '…' : '🎮'}
    </button>
  );
}
