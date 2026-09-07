'use client';

import { useState } from 'react';

type Props = {
  url: string;
  onFallback?: () => void;
};

export default function GameNativeButton({ url, onFallback }: Props) {
  const [busy, setBusy] = useState(false);

  const openNative = async () => {
    setBusy(true);
    try {
      const { InAppBrowser } = await import('@capacitor/inappbrowser');
      await InAppBrowser.openInWebView({
        url,
        options: {
          showURL: true,
          showToolbar: true,
          showNavigationButtons: true,
          closeButtonText: 'Odin',
          allowsBackForwardNavigationGestures: true,
          android: { hardwareBack: true },
          iOS: { enableViewportScale: true, allowsBackForwardNavigationGestures: true },
        },
      });
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
      <button className="button" onClick={openNative} disabled={busy}>
        {busy ? 'Spiel wird geöffnet …' : 'Spiel in Odin öffnen'}
      </button>
      <button className="button secondary" onClick={openSystemBrowser} disabled={busy}>
        Normalen Browser testen
      </button>
    </div>
  );
}
