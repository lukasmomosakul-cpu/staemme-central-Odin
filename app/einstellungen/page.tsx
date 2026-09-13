'use client';

import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import VersionUpdater from '../../components/VersionUpdater';

export default function EinstellungenSeite() {
  const [email, setEmail] = useState('');
  const [team, setTeam] = useState('');

  useEffect(() => {
    (async () => {
      if (!supabase) return;
      const { data } = await supabase.auth.getUser();
      setEmail(data.user?.email ?? '');
      const { data: m } = await supabase.from('team_members').select('team_id,role').limit(1).maybeSingle();
      if (m) {
        const { data: t } = await supabase.from('teams').select('name').eq('id', m.team_id).maybeSingle();
        setTeam(`${t?.name ?? ''} · ${m.role ?? ''}`);
      }
    })();
  }, []);

  const abmelden = async () => {
    await supabase?.auth.signOut();
    window.location.href = '/login/';
  };

  return (
    <div className="shell">
      <main className="main" style={{ paddingBottom: 90 }}>
        <header className="top" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h1 className="title" style={{ margin: 0 }}>Einstellungen</h1>
          <VersionUpdater />
        </header>

        <section className="section card">
          <h2>Konto</h2>
          <div className="muted">{email || 'nicht angemeldet'}</div>
          {team && <div className="muted" style={{ marginTop: 4 }}>{team}</div>}
          <div style={{ marginTop: 12 }}>
            <button type="button" onClick={abmelden}>Abmelden</button>
          </div>
        </section>

        <section className="section card">
          <h2>Bereiche</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <a href="/">Dashboard und Accounts</a>
            <a href="/godbot/">GodBot-Übersicht</a>
            <a href="/team/">Team</a>
            <a href="/scripts/">Scripts</a>
          </div>
        </section>
      </main>

      <nav className="bottomNav" aria-label="Navigation">
        <a href="/protokoll/"><span>📋</span><span>Protokoll</span></a>
        <a className="active" href="/einstellungen/"><span>⚙</span><span>Einstellungen</span></a>
      </nav>
    </div>
  );
}
