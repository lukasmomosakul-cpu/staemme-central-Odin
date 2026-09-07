'use client';

import { useState } from 'react';
import { registerPlugin } from '@capacitor/core';
import { DefaultWebViewOptions, InAppBrowser } from '@capacitor/inappbrowser';

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
      // Open Die Stämme in a real WebView that is displayed inside the Odin app.
      await InAppBrowser.openInWebView({
        url,
        options: DefaultWebViewOptions,
      });
      return;
    } catch {
      try {
        // Fallback: Capacitor's system browser container (Chrome Custom Tab on Android).
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
