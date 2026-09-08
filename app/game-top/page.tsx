'use client';

import { useEffect } from 'react';

const GAME_URL = 'https://www.die-staemme.de/';

export default function GameTopPage() {
  useEffect(() => {
    const account = new URLSearchParams(window.location.search).get('account');
    if (account) localStorage.setItem('odin-selected-game-account', account);
    window.location.replace(GAME_URL);
  }, []);

  return (
    <main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: '#0b1020', color: '#f5f7fb', fontFamily: 'system-ui, sans-serif' }}>
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontSize: 36, marginBottom: 12 }}>🎮</div>
        <strong>Die Stämme wird geöffnet …</strong>
      </div>
    </main>
  );
}
