'use client';

import { useEffect, useMemo, useState } from 'react';
import { supabase } from '../../lib/supabase';
import GameNativeButton from '../../components/GameNativeButton';

const DEFAULT_GAME_URL = 'https://www.die-staemme.de/';
const STORAGE_KEY = 'odin-selected-game-account';

type Account = { id: string; name: string; world: string };

export default function GamePage() {
  const [email, setEmail] = useState<string | null>(null);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedId, setSelectedId] = useState('');
  const [gameUrl, setGameUrl] = useState(DEFAULT_GAME_URL);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!supabase) { setLoading(false); return; }
    let mounted = true;
    const load = async () => {
      setLoading(true);
      const { data: sessionData } = await supabase.auth.getSession();
      const user = sessionData.session?.user;
      if (!mounted) return;
      setEmail(user?.email ?? null);
      if (!user) { setLoading(false); return; }

      const { data: membership, error: membershipError } = await supabase
        .from('team_members').select('team_id').eq('user_id', user.id).limit(1).maybeSingle();
      if (membershipError || !membership) {
        setError('Kein Team gefunden.'); setLoading(false); return;
      }

      const { data: rows, error: accountError } = await supabase
        .from('game_accounts').select('id,name,world,created_at')
        .eq('team_id', membership.team_id).order('created_at', { ascending: false });
      if (accountError) { setError(accountError.message); setLoading(false); return; }
      const list = (rows ?? []) as Account[];
      setAccounts(list);
      const stored = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
      const initial = stored && list.some(a => a.id === stored) ? stored : (list[0]?.id ?? '');
      setSelectedId(initial);
      setLoading(false);
    };
    load();
    return () => { mounted = false; };
  }, []);

  useEffect(() => {
    if (!selectedId || typeof window === 'undefined') return;
    localStorage.setItem(STORAGE_KEY, selectedId);
  }, [selectedId]);

  const selected = accounts.find(a => a.id === selectedId) ?? null;
  const normalizedUrl = useMemo(() => {
    try {
      const value = gameUrl.trim();
      if (!value) return DEFAULT_GAME_URL;
      const parsed = new URL(value);
      if (parsed.protocol !== 'https:') return DEFAULT_GAME_URL;
      return parsed.toString();
    } catch { return DEFAULT_GAME_URL; }
  }, [gameUrl]);

  return (
    <main style={{minHeight:'100vh',padding:'clamp(10px,3vw,16px)',background:'var(--bg,#0b1020)',color:'var(--text,#f5f7fb)'}}>
      <div style={{maxWidth:900,margin:'0 auto',width:'100%'}}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{marginTop:18}}>TEAMZENTRALE ODIN</div>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><div><h1 style={{margin:0,fontSize:'clamp(24px,6vw,36px)'}}>🎮 Die Stämme</h1><div className="muted" style={{marginTop:5}}>{email ? `Angemeldet als ${email}` : 'Nicht angemeldet'}</div></div></div>
          <p className="muted" style={{marginTop:8}}>
            Alle Teammitglieder können jeden Team-Account auswählen. Die Auswahl wird auf diesem Gerät gemerkt.
          </p>

          <div style={{display:'grid',gridTemplateColumns:'repeat(auto-fit,minmax(min(100%,240px),1fr))',gap:10,marginTop:14}}>
            <label>Team-Spielaccount
              <select value={selectedId} onChange={e=>setSelectedId(e.target.value)} disabled={loading || accounts.length===0}>
                {accounts.length===0 && <option value="">{loading ? 'Accounts werden geladen …' : 'Keine Accounts vorhanden'}</option>}
                {accounts.map(a=><option value={a.id} key={a.id}>{a.name} · {a.world}</option>)}
              </select>
            </label>
            <label>Spielseite / Welt-URL
              <input value={gameUrl} onChange={e=>setGameUrl(e.target.value)} placeholder="https://www.die-staemme.de/" inputMode="url" autoCapitalize="none" />
            </label>
          </div>

          {selected && <div className="event" style={{marginTop:12}}><span>👤</span><div style={{flex:1}}><strong>{selected.name}</strong><div className="muted">{selected.world} · gemeinsamer Team-Account</div></div><span className="pill">ausgewählt</span></div>}
          {error && <div className="event" style={{marginTop:12}}><span>⚠️</span><div className="muted">{error}</div></div>}

          <div style={{marginTop:16}}><GameNativeButton url={normalizedUrl} /></div>
        </section>

        <section className="card section" style={{marginTop:14}}>
          <div className="sectionhead"><h2>So läuft es</h2></div>
          <ol className="muted" style={{margin:'8px 0 0 20px',padding:0}}>
            <li>Team-Spielaccount auswählen.</li>
            <li>Auf <strong>Die Stämme öffnen</strong> tippen.</li>
            <li>Falls nötig auf der Spielseite einloggen.</li>
            <li>Beim nächsten Öffnen ist derselbe Account vorausgewählt.</li>
          </ol>
          <p className="muted" style={{marginBottom:0,marginTop:12,fontSize:12}}>
            Odin speichert nur die Auswahl des Team-Accounts. Zugangsdaten und Spiel-Session werden nicht von Odin gespeichert.
          </p>
        </section>

        {!email && <p className="muted" style={{marginTop:14}}>Bitte zuerst in der Teamzentrale anmelden.</p>}
      </div>
    </main>
  );
}
