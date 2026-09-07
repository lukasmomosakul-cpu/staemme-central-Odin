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
      const { InAppBrowser } = await import('@capawesome/capacitor-in-app-browser');
      const native = typeof window !== 'undefined' && 'Capacitor' in window;

      if (!native) {
        window.open(url, '_blank', 'noopener,noreferrer');
        return;
      }

      const fillCredentials = async () => {
        if (!username && !password) return;
        const user = JSON.stringify(username ?? '');
        const pass = JSON.stringify(password ?? '');
        try {
          await InAppBrowser.executeScript({
            code: `(() => {
              const u = ${user};
              const p = ${pass};
              const userSelectors = ['input[name="username"]','input[name="user"]','input[name="login"]','input[type="text"]','input[type="email"]'];
              const passSelectors = ['input[name="password"]','input[name="pass"]','input[type="password"]'];
              const find = (selectors) => selectors.map(s => document.querySelector(s)).find(Boolean);
              const userInput = find(userSelectors);
              const passInput = find(passSelectors);
              if (userInput && u) { userInput.value = u; userInput.dispatchEvent(new Event('input', { bubbles: true })); userInput.dispatchEvent(new Event('change', { bubbles: true })); }
              if (passInput && p) { passInput.value = p; passInput.dispatchEvent(new Event('input', { bubbles: true })); passInput.dispatchEvent(new Event('change', { bubbles: true })); }
            })();`,
          });
        } catch {
          // Filling is best-effort; the game remains fully usable manually.
        }
      };

      const listener = await InAppBrowser.addListener('browserPageLoaded', fillCredentials);
      await InAppBrowser.openInWebView({
        url,
        showURL: true,
        showToolbar: true,
        closeButtonText: 'Schließen',
        showNavigationButtons: true,
        android: { hardwareBack: true, allowZoom: false, pauseMedia: true, isIsolated: false },
      });
      void listener;
      return;
    } catch {
      try {
        const { Browser } = await import('@capacitor/browser');
        await Browser.open({ url });
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
