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
      const { Capacitor, registerPlugin } = await import('@capacitor/core');

      if (Capacitor.isNativePlatform()) {
        const GameWebView = registerPlugin<{
          open: (options: { url: string; username?: string; password?: string }) => Promise<void>;
        }>('GameWebView');
        await GameWebView.open({ url, username, password });
        return;
      }

      window.open(url, '_blank', 'noopener,noreferrer');
    } catch (error) {
      onFallback?.();
      try {
        const { Capacitor } = await import('@capacitor/core');
        if (Capacitor.isNativePlatform()) {
          const message = error instanceof Error ? error.message : String(error);
          window.alert(`Die Stämme konnte nicht innerhalb von Odin geöffnet werden.\n\nFehler: ${message}`);
          return;
        }
      } catch {
        // Fall through to normal web fallback.
      }
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
