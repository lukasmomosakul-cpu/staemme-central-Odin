'use client';

import { useState } from 'react';

const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '1.1.17';

export default function VersionUpdater() {
  const [busy, setBusy] = useState(false);

  const update = () => {
    if (busy) return;

    const android = (window as any).Android;

    if (!android || typeof android.updateApk !== 'function') {
      alert('Updater ist in dieser App-Version nicht verfügbar.');
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
      title="Odin aktualisieren"
      aria-label="Odin aktualisieren"
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
      v{APP_VERSION}
    </button>
  );
}
