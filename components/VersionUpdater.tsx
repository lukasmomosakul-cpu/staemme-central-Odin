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

  // 02.10.2026: EINMAL die Versionsnummer, als kleiner Knopf - Antippen laedt
  // die neueste APK. (Vorher stand sie doppelt, danach nur "APK".)
  return (
    <button
      id="odin-version-updater-button"
      type="button"
      onClick={update}
      disabled={busy}
      title="Neueste Odin-APK laden"
      aria-label={`Odin v${APP_VERSION} - neueste APK laden`}
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        gap: 5,
        border: '1px solid rgba(184,137,63,.35)',
        background: 'rgba(184,137,63,.10)',
        color: '#7a5a24',
        borderRadius: 999,
        padding: '4px 10px',
        margin: 0,
        font: '700 11px/1 inherit',
        letterSpacing: '.02em',
        cursor: busy ? 'wait' : 'pointer',
        whiteSpace: 'nowrap',
        flexShrink: 0,
        opacity: busy ? 0.65 : 1,
      }}
    >
      v{APP_VERSION}<span aria-hidden="true" style={{ fontSize: 12, lineHeight: 1 }}>⤓</span>
    </button>
  );
}
