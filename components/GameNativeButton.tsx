'use client';

import { useState } from 'react';

type Props = {
  url: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openInAppBrowser = async () => {
    setBusy(true);
    try {
      // Use the platform browser container (Chrome Custom Tab / SFSafariViewController)
      // instead of an embedded WebView. This keeps the game in the Odin app flow while
      // giving the login page a normal browser session/cookie environment.
      const { Browser } = await import('@capacitor/browser');
      await Browser.open({ url });
    } catch {
      onFallback?.();
      window.open(url, '_blank', 'noopener,noreferrer');
    } finally {
      setBusy(false);
    }
  };

  const openSystemBrowser = async () => {
    try {
      const { InAppBrowser } = await import('@capacitor/inappbrowser');
      await InAppBrowser.openInExternalBrowser({ url });
    } catch {
      window.open(url, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
      <button className="button" onClick={openInAppBrowser} disabled={busy}>
        {busy ? 'Spiel wird geöffnet …' : 'Spiel in Odin öffnen'}
      </button>
      <button className="button secondary" onClick={openSystemBrowser} disabled={busy}>
        Normalen Browser testen
      </button>
    </div>
  );
}
