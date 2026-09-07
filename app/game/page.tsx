'use client';

import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import GameNativeButton from '../../components/GameNativeButton';

const DEFAULT_GAME_URL = 'https://www.die-staemme.de/';

export default function GamePage() {
  const [email, setEmail] = useState<string | null>(null);
  const [gameUrl, setGameUrl] = useState(DEFAULT_GAME_URL);
  const [accountName, setAccountName] = useState('');

  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getSession().then(({ data }) => setEmail(data.session?.user?.email ?? null));
  }, []);

  const normalizedUrl = useMemo(() => {
    try {
      const value = gameUrl.trim();
      if (!value) return DEFAULT_GAME_URL;
      const parsed = new URL(value);
      if (parsed.protocol !== 'https:') return DEFAULT_GAME_URL;
      return parsed.toString();
    } catch {
      return DEFAULT_GAME_URL;
    }
  }, [gameUrl]);

  return (
    <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,16px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}>
      <div style={{maxWidth:900,margin:'0 auto',width:'100%'}}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{marginTop:18}}>TEAMZENTRALE ODIN</div>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><h1 style={{margin:0,fontSize:'clamp(24px,6vw,36px)'}}>🎮 Die Stämme</h1></div>
          <p className="muted" style={{marginTop:8}}>
            Odin öffnet das Spiel in einem integrierten Browser-Fenster. Wenn ein Login nötig ist, meldest du dich dort einmal an; danach bleibt das Spiel in dieser Ansicht.
          </p>

          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(min(100%,240px),1fr))',gap:10,marginTop:14}}>
            <label>Odin-Spielaccount
              <input value={accountName} onChange={e=>setAccountName(e.target.value)} placeholder="z. B. Lukas auf Welt 258" />
            </label>
            <label>Spielseite / Welt-URL
              <input value={gameUrl} onChange={e=>setGameUrl(e.target.value)} placeholder="https://www.die-staemme.de/" inputMode="url" autoCapitalize="none" />
            </label>
          </div>

          <div style={{marginTop:16}}>
            <GameNativeButton url={normalizedUrl} />
          </div>
        </section>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><h2>So läuft es</h2></div>
          <ol className="muted" style={{margin:'8px 0 0 20px',padding:0}}>
            <li>Auf <strong>Die Stämme öffnen</strong> tippen.</li>
            <li>Falls nötig auf der Spielseite einloggen.</li>
            <li>Danach ganz normal im Spiel weitermachen – Odin bleibt die Start- und Verwaltungsoberfläche.</li>
          </ol>
          <p className="muted" style={{marginBottom:0,marginTop:12,fontSize:12}}>
            Der Login läuft nicht durch einen Odin-Proxy. Zugangsdaten und Spiel-Session werden nicht von Odin gespeichert.
          </p>
        </section>

        {!email && <p className="muted" style={{marginTop:14}}>Bitte zuerst in der Teamzentrale anmelden.</p>}
      </div>
    </main>
  );
}
