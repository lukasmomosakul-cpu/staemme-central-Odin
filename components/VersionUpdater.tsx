'use client';

import { useState } from 'react';

// Kein fester Fallback: eine falsche Versionsnummer waere schlimmer als ein
// sichtbares '?', weil die Anzeige genau dazu dient, einen Deploy zu pruefen.
const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '?';

export default function VersionUpdater() {
  const [busy, setBusy] = useState(false);

  const update = () => {
    if (busy) return;

    const android = (window as any).Android;

    // 02.10.2026: ausserhalb der App (PC-Browser) direkt die neueste APK.
    if (!android || typeof android.updateApk !== 'function') {
      window.open('https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest/download/odin-latest.apk', '_blank');
      return;
    }

    setBusy(true);

    try {
      android.updateApk();
      window.setTimeout(() => setBusy(false), 1500);
    } catch {
      setBusy(false);
      alert('Der Updater konnte nicht gestartet werden.');
    }
  };

  return (
    <button
      id="odin-version-updater-button"
      type="button"
      onClick={update}
      disabled={busy}
      title={`Neueste Odin-APK laden (installiert: v${APP_VERSION})`}
      aria-label="Neueste Odin-APK laden"
      style={{
        border: 0,
        background: 'transparent',
        padding: 0,
        margin: 0,
        color: '#64748b',
        font: '700 12px inherit',
        cursor: busy ? 'wait' : 'pointer',
        textDecoration: 'underline',
        textUnderlineOffset: 3,
        whiteSpace: 'nowrap',
        opacity: busy ? 0.65 : 1,
      }}
    >
      ⬇ APK
    </button>
  );
}
