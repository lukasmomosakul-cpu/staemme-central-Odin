'use client';

import { useState } from 'react';

const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '1.1.4';
const APK_URL = 'https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest/download/odin-latest.apk';

export default function VersionUpdater() {
  const [busy, setBusy] = useState(false);
  const update = () => {
    if (busy) return;
    setBusy(true);
    try {
      const bridge = (window as any).Android;
      if (bridge && typeof bridge.updateApk === 'function') {
        bridge.updateApk();
        return;
      }
      window.location.href = APK_URL;
    } catch {
      setBusy(false);
      window.location.href = APK_URL;
    }
  };

  return (
    <button type="button" onClick={update} disabled={busy} title="Neueste Odin-Version installieren" aria-label="Neueste Odin-Version installieren" style={{border:0,background:'transparent',padding:0,margin:0,color:'#64748b',font:'700 12px inherit',cursor:busy?'wait':'pointer',textDecoration:'underline',textUnderlineOffset:3,whiteSpace:'nowrap',opacity:busy?.65:1}}>
      v{APP_VERSION}
    </button>
  );
}
