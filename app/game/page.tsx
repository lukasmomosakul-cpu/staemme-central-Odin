'use client';

import { Suspense, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '../../lib/supabase';
import GameNativeButton from '../../components/GameNativeButton';

const DEFAULT_GAME_URL = 'https://www.die-staemme.de/';
const STORAGE_KEY = 'odin-selected-game-account';
type Account = { id: string; name: string; world: string };

function GamePageContent() {
  const searchParams = useSearchParams();
  const requestedAccount = searchParams.get('account');
  const [email, setEmail] = useState<string | null>(null);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedId, setSelectedId] = useState('');
  const [gameUrl] = useState(DEFAULT_GAME_URL);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!supabase) {
      setLoading(false);
      return;
    }

    let mounted = true;
    (async () => {
      setLoading(true);
      setError('');
      const { data: sessionData } = await supabase.auth.getSession();
      const user = sessionData.session?.user;
      if (!mounted) return;
      setEmail(user?.email ?? null);
      if (!user) {
        setLoading(false);
        return;
      }

      const { data: membership, error: membershipError } = await supabase
        .from('team_members')
        .select('team_id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

      if (membershipError || !membership) {
        setError('Kein Team gefunden.');
        setLoading(false);
        return;
      }

      const { data: rows, error: accountError } = await supabase
        .from('game_accounts')
        .select('id,name,world,created_at')
        .eq('team_id', membership.team_id)
        .order('created_at', { ascending: false });

      if (accountError) {
        setError(accountError.message);
        setLoading(false);
        return;
      }

      const list = (rows ?? []) as Account[];
      setAccounts(list);
      const stored = typeof window !== 'undefined' ? localStorage.getItem(STORAGE_KEY) : null;
      const initial = requestedAccount && list.some(a => a.id === requestedAccount)
        ? requestedAccount
        : stored && list.some(a => a.id === stored)
          ? stored
          : list[0]?.id ?? '';
      setSelectedId(initial);
      setLoading(false);
    })();

    return () => { mounted = false; };
  }, [requestedAccount]);

  useEffect(() => {
    if (selectedId && typeof window !== 'undefined') localStorage.setItem(STORAGE_KEY, selectedId);
  }, [selectedId]);

  const selected = accounts.find(a => a.id === selectedId) ?? null;
  const normalizedUrl = useMemo(() => {
    try {
      const parsed = new URL(gameUrl.trim() || DEFAULT_GAME_URL);
      return parsed.protocol === 'https:' ? parsed.toString() : DEFAULT_GAME_URL;
    } catch {
      return DEFAULT_GAME_URL;
    }
  }, [gameUrl]);

  return (
    <main style={{ minHeight: '100vh', padding: 'clamp(10px,3vw,16px)', background: 'var(--bg,#0b1020)', color: 'var(--text,#f5f7fb)' }}>
      <div style={{ maxWidth: 900, margin: '0 auto', width: '100%' }}>
        <a href="/" className="muted">← Zur Teamzentrale</a>
        <div className="eyebrow" style={{ marginTop: 18 }}>TEAMZENTRALE ODIN</div>

        <section className="card section" style={{ marginTop: 14 }}>
          <div className="sectionhead">
            <div>
              <h1 style={{ margin: 0, fontSize: 'clamp(24px,6vw,36px)' }}>🎮 Die Stämme</h1>
              <div className="muted" style={{ marginTop: 5 }}>{email ? 'Angemeldet' : 'Nicht angemeldet'}</div>
            </div>
            {selected && <span className="pill">{selected.name} · {selected.world}</span>}
          </div>

          {loading && <div className="muted" style={{ marginTop: 14 }}>Account wird geladen …</div>}
          {!loading && !selected && !error && <div className="event" style={{ marginTop: 14 }}><span>ℹ️</span><div className="muted">Kein Spielaccount ausgewählt. Bitte zuerst einen Account in der Teamzentrale öffnen.</div></div>}
          {error && <div className="event" style={{ marginTop: 12 }}><span>⚠️</span><div className="muted">{error}</div></div>}

          {selected && (
            <div className="event" style={{ marginTop: 14 }}>
              <span>🎮</span>
              <div style={{ flex: 1 }}>
                <strong>{selected.name}</strong>
                <div className="muted">Welt {selected.world} · gemeinsamer Team-Account</div>
              </div>
              <span className="pill">bereit</span>
            </div>
          )}

          <div style={{ marginTop: 16 }}>
            <GameNativeButton url={normalizedUrl} />
          </div>
          <div className="muted" style={{ marginTop: 8, fontSize: 13 }}>
            Das Spiel wird auf Android in einem In-App-WebView geöffnet. Der Account wurde bereits in der Teamzentrale ausgewählt.
          </div>
        </section>

        <section className="card section" style={{ marginTop: 14 }}>
          <div className="sectionhead">
            <h2>Werkzeuge</h2>
            <a className="button secondary" href="/scripts">🧩 Scripts</a>
          </div>
          <div className="muted">Script-Verwaltung, Benachrichtigungen und weitere Einstellungen werden zentral über Odin aufgebaut.</div>
        </section>
      </div>
    </main>
  );
}

export default function GamePage() {
  return (
    <Suspense fallback={<main style={{ minHeight: '100vh', padding: 16, background: 'var(--bg,#0b1020)', color: 'var(--text,#f5f7fb)' }}><div className="muted">Spiel wird geladen …</div></main>}>
      <GamePageContent />
    </Suspense>
  );
}
