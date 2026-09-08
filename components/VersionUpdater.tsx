'use client';

import { Browser } from '@capacitor/browser';

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
    <button type="button" onClick={update} title="Auf die neueste Odin-Version aktualisieren" aria-label="Auf die neueste Odin-Version aktualisieren" style={{border:0,background:'transparent',padding:0,margin:0,color:'inherit',font: 'inherit',cursor:'pointer',textDecoration:'underline',textUnderlineOffset:3}}>
      <span>Odin aktualisieren</span>
    </button>
  );
}
