'use client';

import { Browser } from '@capacitor/browser';

const APP_VERSION = process.env.NEXT_PUBLIC_APP_VERSION || '1.1.3';
const APK_URL = 'https://github.com/lukasmomosakul-cpu/staemme-central-Odin/releases/latest/download/odin-latest.apk';

export default function VersionUpdater() {
  const update = async () => {
    try {
      await Browser.open({ url: APK_URL, toolbarColor: '#0b1020', presentationStyle: 'fullscreen' });
    } catch {
      window.location.href = APK_URL;
    }
  };

  return (
    <button type="button" onClick={update} title="Neueste Odin-Version herunterladen" aria-label="Neueste Odin-Version herunterladen" style={{border:0,background:'transparent',padding:0,margin:0,color:'#64748b',font:'700 12px inherit',cursor:'pointer',textDecoration:'underline',textUnderlineOffset:3,whiteSpace:'nowrap'}}>
      v{APP_VERSION}
    </button>
  );
}
