'use client';

import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import GameNativeButton from '../../components/GameNativeButton';

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
    setNotice('Web-Fallback: Die iframe-Einbettung kann beim Login durch Cookie-, Redirect- oder Frame-Regeln der Spielseite eingeschränkt sein.');
  };

  return (
    <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,16px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}>
      <div style={{maxWidth:1280,margin:'0 auto',width:'100%'}}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{marginTop:18}}>TEAMZENTRALE ODIN</div>
        <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',gap:10,flexWrap:'wrap'}}>
          <div style={{minWidth:0}}>
            <h1 style={{marginBottom:6,fontSize:'clamp(24px,6vw,36px)',lineHeight:1.1}}>🎮 Die Stämme in Odin</h1>
            <p className="muted" style={{marginTop:0}}>Web-Fallback plus vorbereitete native Spielansicht.</p>
          </div>
          <span className="pill online">Normale IP</span>
        </div>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><h2>Spielverbindung</h2></div>
          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(min(100%,240px),1fr))',gap:10}}>
            <label>Odin-Spielaccount
              <input value={accountName} onChange={e=>setAccountName(e.target.value)} placeholder="z. B. Lukas auf Welt 258" />
            </label>
            <label>Spielseite / Welt-URL
              <input value={gameUrl} onChange={e=>setGameUrl(e.target.value)} placeholder="https://www.die-staemme.de/" inputMode="url" autoCapitalize="none" />
            </label>
          </div>
          <div style={{display:'flex',gap:8,flexWrap:'wrap',marginTop:12}}>
            <GameNativeButton url={normalizedUrl} onFallback={() => setNotice('Native Spielansicht ist nur im Odin-Native-Container verfügbar. Der Browser-Fallback wurde geöffnet.')} />
            <button className="button secondary" onClick={openGame}>Web-Fallback</button>
            <a className="button secondary" href={normalizedUrl} target="_blank" rel="noopener noreferrer">Extern öffnen</a>
          </div>
          {notice && <div className="toast" style={{marginTop:10}}>{notice}</div>}
        </section>

        <section className="card" style={{marginTop:14,padding:0,overflow:'hidden'}}>
          <div style={{padding:'10px 12px',borderBottom:'1px solid rgba(255,255,255,.08)',display:'flex',justifyContent:'space-between',gap:8,alignItems:'center'}}>
            <div style={{minWidth:0}}><strong>Web-Fallback</strong><div className="muted" style={{fontSize:11,marginTop:2,overflow:'hidden',textOverflow:'ellipsis',whiteSpace:'nowrap',maxWidth:'70vw'}}>{activeUrl}</div></div>
            <button className="button secondary" onClick={openGame}>Neu laden</button>
          </div>
          <div style={{width:'100%',height:'calc(100vh - 250px)',minHeight:'min(620px,70vh)',background:'#111827'}}>
            <iframe
              key={frameKey}
              src={activeUrl}
              title="Die Stämme – Spiel"
              style={{width:'100%',height:'100%',border:0,display:'block',background:'#fff'}}
              allow="fullscreen"
            />
          </div>
        </section>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><h2>Was wir jetzt geändert haben</h2></div>
          <p className="muted" style={{marginBottom:8}}>Die Web-App bleibt als Fallback erhalten. Zusätzlich ist jetzt die native In-App-WebView-Schnittstelle vorbereitet. In einem Capacitor-Container kann Odin die Spielseite als eigene WebView öffnen, statt sie als Cross-Origin-iframe einzubetten.</p>
          <p className="muted" style={{marginBottom:0}}>Das ist bewusst kein Proxy und keine Umgehung von Spielserver-Schutzmechanismen. Odin speichert weiterhin keine Spielpasswörter oder Session-Cookies.</p>
        </section>

        {!email && <p className="muted" style={{marginTop:14}}>Bitte zuerst in der Teamzentrale anmelden.</p>}
      </div>
    </main>
  );
}
