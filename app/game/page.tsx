'use client';

import { Suspense, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { supabase } from '../../lib/supabase';

const DEFAULT_GAME_URL = 'https://www.die-staemme.de/';
const STORAGE_KEY = 'odin-selected-game-account';
type Account = { id: string; name: string; world: string };

function GamePageContent() {
  const searchParams = useSearchParams();
  const requestedAccount = searchParams.get('account');
  const [email, setEmail] = useState<string | null>(null);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [selectedId, setSelectedId] = useState('');
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
  const gameUrl = useMemo(() => DEFAULT_GAME_URL, []);

  return (
    <main style={{ height: '100vh', display: 'flex', flexDirection: 'column', background: '#0b1020', color: '#f5f7fb', overflow: 'hidden' }}>
      <header style={{ flex: '0 0 auto', minHeight: 52, display: 'flex', alignItems: 'center', gap: 10, padding: '8px 12px', borderBottom: '1px solid rgba(255,255,255,.12)', background: '#111827', zIndex: 2 }}>
        <a href="/" className="button secondary" style={{ whiteSpace: 'nowrap' }}>← Odin</a>
        <div style={{ minWidth: 0, flex: 1 }}>
          <strong style={{ display: 'block', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>🎮 Die Stämme</strong>
          <span style={{ fontSize: 12, opacity: .7 }}>{selected ? `${selected.name} · Welt ${selected.world}` : email ? 'Angemeldet' : 'Nicht angemeldet'}</span>
        </div>
        <a href="/scripts" className="button secondary" style={{ whiteSpace: 'nowrap' }}>🧩 Scripts</a>
      </header>

      {loading && <div style={{ padding: 10, fontSize: 13, opacity: .75 }}>Account wird geladen …</div>}
      {error && <div style={{ padding: 10, fontSize: 13 }}>⚠️ {error}</div>}
      {!loading && !selected && !error && <div style={{ padding: 10, fontSize: 13, opacity: .75 }}>Kein Spielaccount ausgewählt. Das Spiel kann trotzdem geöffnet werden.</div>}

      <div style={{ flex: 1, minHeight: 0, position: 'relative', background: '#fff' }}>
        <iframe
          src={gameUrl}
          title="Die Stämme"
          allow="fullscreen"
          referrerPolicy="strict-origin-when-cross-origin"
          style={{ display: 'block', width: '100%', height: '100%', border: 0 }}
        />
      </div>
    </main>
  );
}

export default function GamePage() {
  return (
    <Suspense fallback={<main style={{ minHeight: '100vh', padding: 16, background: '#0b1020', color: '#f5f7fb' }}><div>Spiel wird geladen …</div></main>}>
      <GamePageContent />
    </Suspense>
  );
}
