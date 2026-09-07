'use client';

import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';

const DEFAULT_GAME_URL = 'https://www.die-staemme.de/';

export default function GamePage() {
  const [email, setEmail] = useState<string | null>(null);
  const [gameUrl, setGameUrl] = useState(DEFAULT_GAME_URL);
  const [activeUrl, setActiveUrl] = useState(DEFAULT_GAME_URL);
  const [accountName, setAccountName] = useState('');
  const [notice, setNotice] = useState('');
  const [frameKey, setFrameKey] = useState(0);

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

  const openGame = () => {
    setActiveUrl(normalizedUrl);
    setFrameKey((value) => value + 1);
    setNotice('Spielseite wird direkt in Odin geladen. Wenn der Spielserver das Einbetten blockiert, zeigt der Browser dies im Spielfenster an.');
  };

  return (
    <main style={{minHeight:'100vh',padding:'16px',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}>
      <div style={{maxWidth:1280,margin:'0 auto'}}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{marginTop:22}}>TEAMZENTRALE ODIN</div>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:12,flexWrap:'wrap'}}>
          <div>
            <h1 style={{marginBottom:6}}>🎮 Die Stämme direkt in Odin</h1>
            <p className="muted" style={{marginTop:0}}>Das echte Spiel-Fenster wird hier eingebettet – keine Kopie der Spieloberfläche.</p>
          </div>
          <span className="pill online">Browser-Spiel</span>
        </div>

        <section className="card section" style={{marginTop:18}}>
          <div className="sectionhead"><h2>Spielverbindung</h2><span className="pill">Aktuell: normale IP</span></div>
          <div style={{display:'grid',gridTemplateColumns:'minmax(0,1fr) minmax(0,2fr)',gap:12}}>
            <label>Odin-Spielaccount
              <input value={accountName} onChange={e=>setAccountName(e.target.value)} placeholder="z. B. Lukas auf Welt 258" />
            </label>
            <label>Spielseite / Welt-URL
              <input value={gameUrl} onChange={e=>setGameUrl(e.target.value)} placeholder="https://www.die-staemme.de/ oder eine Welt-URL" inputMode="url" autoCapitalize="none" />
            </label>
          </div>
          <div style={{display:'flex',gap:10,flexWrap:'wrap',marginTop:14}}>
            <button className="button" onClick={openGame}>Spiel in Odin öffnen</button>
            <a className="button" href={normalizedUrl} target="_blank" rel="noreferrer">Falls nötig extern öffnen</a>
          </div>
          {notice && <div className="toast" style={{marginTop:12}}>✓ {notice}</div>}
        </section>

        <section className="card" style={{marginTop:18,padding:0,overflow:'hidden'}}>
          <div style={{padding:'12px 14px',borderBottom:'1px solid rgba(255,255,255,.08)',display:'flex',justifyContent:'space-between',gap:10,alignItems:'center'}}>
            <div><strong>Spiel-Fenster</strong><div className="muted" style={{fontSize:12,marginTop:3,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',maxWidth:'75vw'}}>{activeUrl}</div></div>
            <button className="button secondary" onClick={openGame}>Neu laden</button>
          </div>
          <div style={{width:'100%',height:'calc(100vh - 290px)',minHeight:620,background:'#111827'}}>
            <iframe
              key={frameKey}
              src={activeUrl}
              title="Die Stämme – Spiel"
              style={{width:'100%',height:'100%',border:0,display:'block',background:'#fff'}}
              allow="fullscreen"
            />
          </div>
        </section>

        <section className="card section" style={{marginTop:18}}>
          <div className="sectionhead"><h2>Wichtig für den nächsten Schritt</h2></div>
          <div className="list">
            <div className="event"><span>1️⃣</span><div><strong>Zuerst echte Spielseite</strong><div className="muted">Odin versucht jetzt, die originale Seite direkt innerhalb der App anzuzeigen.</div></div></div>
            <div className="event"><span>2️⃣</span><div><strong>Login bleibt beim Spiel</strong><div className="muted">Odin speichert keine Spielpasswörter. Die bestehende Browser-Session wird nicht ausgelesen.</div></div></div>
            <div className="event"><span>3️⃣</span><div><strong>IP-Infrastruktur bleibt entkoppelt</strong><div className="muted">Die vorläufige Verbindung läuft über die normale IP. Später kann die Zuordnung Spielaccount → Netzwerkprofil → feste Egress-IP ergänzt werden.</div></div></div>
            <div className="event"><span>4️⃣</span><div><strong>Wenn Einbettung blockiert wird</strong><div className="muted">Dann bauen wir nicht einfach einen fragilen Proxy. Wir prüfen stattdessen die technisch saubere Browser-/WebView-Variante für die gewünschte Nutzung.</div></div></div>
          </div>
        </section>

        {!email && <p className="muted" style={{marginTop:18}}>Bitte zuerst in der Teamzentrale anmelden.</p>}
      </div>
    </main>
  );
}
