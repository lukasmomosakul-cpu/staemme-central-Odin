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
      await ExternalBrowser.open({ url });
    } catch {
      onFallback?.();
      window.open(url, '_blank', 'noopener,noreferrer');
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
