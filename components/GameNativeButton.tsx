'use client';

import { useState } from 'react';

type Props = {
  url: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openGame = async () => {
    setBusy(true);
    try {
      // Die Stämme needs the real browser session for its login/session cookies.
      // Android WebView/embedded sessions are isolated from the user's normal browser.
      const { InAppBrowser } = await import('@capacitor/inappbrowser');
      await InAppBrowser.openInExternalBrowser({ url });
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
