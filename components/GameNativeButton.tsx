'use client';

import { useState } from 'react';
import { registerPlugin } from '@capacitor/core';

type Props = {
  url: string;
  onFallback?: () => void;
};

type ExternalBrowserPlugin = {
  open(options: { url: string }): Promise<void>;
};

const ExternalBrowser = registerPlugin<ExternalBrowserPlugin>('ExternalBrowser');

export default function GameNativeButton({ url, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openGame = async () => {
    setBusy(true);
    try {
      // First use Capacitor's official browser container (Chrome Custom Tab on Android).
      // If the plugin is unavailable, fall back to our native ACTION_VIEW bridge.
      const { Browser } = await import('@capacitor/browser');
      await Browser.open({ url });
      return;
    } catch {
      try {
        await ExternalBrowser.open({ url });
        return;
      } catch {
        onFallback?.();
        window.open(url, '_blank', 'noopener,noreferrer');
      }
    } finally {
      setBusy(false);
    }
  };

  return (
    <button className="button" onClick={openGame} disabled={busy}>
      {busy ? 'Spiel wird geöffnet …' : 'Die Stämme öffnen'}
    </button>
  );
}
